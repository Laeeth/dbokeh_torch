import sbt._
import Keys._

import com.untyped.sbtjs.Plugin.{JsKeys,jsSettings=>pluginJsSettings,CompilationLevel,VariableRenamingPolicy}

import LessPlugin.{LessKeys,lessSettings=>pluginLessSettings}
import EcoPlugin.{EcoKeys,ecoSettings=>pluginEcoSettings}

object BokehJS {
    object BokehJSKeys {
        val requirejs = taskKey[Seq[File]]("Run RequireJS optimizer")
        val requirejsConfig = settingKey[RequireJSSettings]("RequireJS settings")

        val bokehjsVersion = taskKey[String]("BokehJS version as obtained from src/coffee/main.coffe")
        val writeProps = taskKey[Seq[File]]("Write BokehJS configuration to bokehjs.properties")

        val copyVendor = taskKey[Seq[File]]("Copy vendor/** from src to build")
        val copyCSS = taskKey[Seq[File]]("Generate bokeh.min.css")
    }

    import BokehJSKeys._

    lazy val jsSettings = pluginJsSettings ++ Seq(
        sourceDirectory in (Compile, JsKeys.js) <<= (sourceDirectory in Compile)(_ / "coffee"),
        resourceManaged in (Compile, JsKeys.js) <<= (resourceManaged in Compile)(_ / "js"),
        compile in Compile <<= compile in Compile dependsOn (JsKeys.js in Compile),
        resourceGenerators in Compile <+= JsKeys.js in Compile,
        JsKeys.compilationLevel in (Compile, JsKeys.js) := CompilationLevel.WHITESPACE_ONLY,
        JsKeys.variableRenamingPolicy in (Compile, JsKeys.js) := VariableRenamingPolicy.OFF,
        JsKeys.prettyPrint in (Compile, JsKeys.js) := true)

    lazy val lessSettings = pluginLessSettings ++ Seq(
        sourceDirectory in (Compile, LessKeys.less) <<= (sourceDirectory in Compile)(_ / "less"),
        resourceManaged in (Compile, LessKeys.less) <<= (resourceManaged in Compile)(_ / "css"),
        compile in Compile <<= compile in Compile dependsOn (LessKeys.less in Compile),
        resourceGenerators in Compile <+= LessKeys.less in Compile,
        includeFilter in (Compile, LessKeys.less) := "bokeh.less")

    lazy val ecoSettings = pluginEcoSettings ++ Seq(
        sourceDirectory in (Compile, EcoKeys.eco) <<= sourceDirectory in (Compile, JsKeys.js),
        resourceManaged in (Compile, EcoKeys.eco) <<= resourceManaged in (Compile, JsKeys.js),
        compile in Compile <<= compile in Compile dependsOn (EcoKeys.eco in Compile),
        resourceGenerators in Compile <+= EcoKeys.eco in Compile)

    lazy val requirejsSettings = Seq(
        requirejsConfig in Compile := {
            val srcDir = sourceDirectory in Compile value;
            val jsDir = resourceManaged in (Compile, JsKeys.js) value
            def frag(name: String) = srcDir / "js" / s"_$name.js.frag"
            RequireJSSettings(
                baseUrl        = jsDir,
                mainConfigFile = jsDir / "config.js",
                name           = "vendor/almond/almond",
                include        = List("main"),
                wrapShim       = true,
                wrap           = Some((frag("start"), frag("end"))),
                out            = jsDir / "bokeh.js")
        },
        requirejs in Compile <<= Def.task {
            val log = streams.value.log
            val settings = (requirejsConfig in Compile).value

            log.info(s"Optimizing and minifying sbt-requirejs source ${settings.out}")
            val rjs = new RequireJS(log, settings)
            val (opt, min) = rjs.optimizeAndMinify

            val optFile = settings.out
            val minFile = file(optFile.getPath.stripSuffix("js") + "min.js")

            IO.write(optFile, opt)
            IO.write(minFile, min)

            Seq(optFile, minFile)
        } dependsOn (JsKeys.js in Compile)
          dependsOn (EcoKeys.eco in Compile)
          dependsOn (BokehJSKeys.copyVendor in Compile),
        compile in Compile <<= compile in Compile dependsOn (requirejs in Compile),
        resourceGenerators in Compile <+= requirejs in Compile)

    lazy val pluginSettings = jsSettings ++ lessSettings ++ ecoSettings ++ requirejsSettings

    lazy val bokehjsSettings = pluginSettings ++ Seq(
        sourceDirectory in Compile := baseDirectory.value / "src",
        bokehjsVersion <<= Def.task {
            val srcDir = sourceDirectory in (Compile, JsKeys.js) value
            val jsMain = srcDir / "main.coffee"
            val regex = """^\s*Bokeh.version = '(.*)'\s*$""".r
            IO.readLines(jsMain) collectFirst {
                case regex(version) => version
            } getOrElse {
                sys.error(s"Unable to read BokehJS version from $jsMain")
            }
        },
        writeProps in Compile <<= Def.task {
            val resDir = resourceManaged in Compile value
            val outFile = resDir / "bokehjs.properties"
            val version = bokehjsVersion value
            val props = s"bokehjs.version=$version"
            IO.write(outFile, props)
            Seq(outFile)
        },
        resourceGenerators in Compile <+= writeProps in Compile,
        copyVendor in Compile <<= Def.task {
            val srcDir = sourceDirectory in Compile value
            val resDir = resourceManaged in (Compile, JsKeys.js) value
            val source = srcDir / "vendor"
            val target = resDir / "vendor"
            val toCopy = (PathFinder(source) ***) pair Path.rebase(source, target)
            IO.copy(toCopy, overwrite=true).toSeq
        },
        resourceGenerators in Compile <+= copyVendor in Compile,
        copyCSS in Compile <<= Def.task {
            val cssDir = resourceManaged in (Compile, LessKeys.less) value
            val inFile = cssDir / "bokeh.css"
            val outFile = cssDir / "bokeh.min.css"
            IO.copyFile(inFile, outFile)
            Seq(outFile)
        } dependsOn (LessKeys.less in Compile),
        resourceGenerators in Compile <+= copyCSS in Compile)
}


import sbt._
import Keys._

import com.untyped.sbtgraph.{Graph,Source,Descendents}

import org.mozilla.javascript.tools.shell.Global
import org.mozilla.javascript.{Context,Scriptable,Callable}

import scala.collection.JavaConverters._
import java.nio.charset.Charset

object EcoPlugin extends sbt.Plugin {
    case class EcoSource(graph: EcoGraph, src: File) extends Source with Rhino {
        type S = EcoSource
        type G = EcoGraph

        val parents: List[EcoSource] = Nil

        def isTemplated: Boolean =
            src.getPath.contains(".template")

        val modules = List("eco", ".")

        def modulePaths: List[String] = {
            val baseUrl = getClass.getClassLoader.getResource("")
            val baseDir = file(baseUrl.getPath)
            modules.map(baseDir / _).map(_.toURI.toString)
        }

        def ecoScope(ctx: Context): Scriptable = {
            val global = new Global()
            global.init(ctx)

            val require = global.installRequire(ctx, modulePaths.asJava, false)
            require.requireMain(ctx, "compiler")
        }

        def compile: Option[File] = {
            des.map { des =>
                graph.log.info(s"Compiling ${graph.pluginName} source $des")
                withContext { ctx =>
                    val scope = ecoScope(ctx)
                    val ecoCompiler = scope.get("precompile", scope).asInstanceOf[Callable]
                    val args = Array[AnyRef](IO.read(src))
                    val output = ecoCompiler.call(ctx, scope, scope, args).asInstanceOf[String]
                    IO.write(des, output)
                    des
                }
            }
        }
    }

    case class EcoGraph(log: Logger, sourceDirs: Seq[File], targetDir: File) extends Graph {
        type S = EcoSource

        val pluginName = "sbt-eco"

        val templateProperties = null
        val downloadDir        = null

        def createSource(src: File): EcoSource =
            EcoSource(this, src.getCanonicalFile)

        def srcFilenameToDesFilename(filename: String) =
            filename.stripSuffix("eco") + "js"
    }

    object EcoKeys {
        val eco = taskKey[Seq[File]]("Compile ECO templates")
        val ecoGraph = taskKey[EcoGraph]("Collection of ECO templates")
    }

    import EcoKeys._

    def ecoGraphTask = Def.task {
        val graph = EcoGraph(
            log        = streams.value.log,
            sourceDirs = (sourceDirectories in eco).value,
            targetDir  = (resourceManaged in eco).value)

        (unmanagedSources in eco).value.foreach(graph += _)
        graph
    }

    def unmanagedSourcesTask = Def.task {
        val include = includeFilter in eco value
        val exclude = excludeFilter in eco value

        (sourceDirectories in eco).value.foldLeft(Seq[File]()) {
            (acc, sourceDir) => acc ++ Descendents(sourceDir, include, exclude).get
        }
    }

    def watchSourcesTask = Def.task {
        val graph = (ecoGraph in eco).value
        graph.sources.map(_.src): Seq[File]
    }

    def compileTask = Def.task {
        val sources = (unmanagedSources in eco).value
        val graph = (ecoGraph in eco).value
        graph.compileAll(sources)
    }

    def cleanTask = Def.task {
        val graph = (ecoGraph in eco).value
        graph.sources.foreach(_.clean())
    }

    def ecoSettingsIn(conf: Configuration): Seq[Setting[_]] = {
        inConfig(conf)(Seq(
            includeFilter in eco     :=  "*.eco",
            excludeFilter in eco     :=  (".*" - ".") || "_*" || HiddenFileFilter,
            sourceDirectory in eco   <<= (sourceDirectory in conf),
            sourceDirectories in eco <<= (sourceDirectory in (conf, eco)) { Seq(_) },
            unmanagedSources in eco  <<= unmanagedSourcesTask,
            resourceManaged in eco   <<= resourceManaged in conf,
            sources in eco           <<= watchSourcesTask,
            watchSources in eco      <<= watchSourcesTask,
            clean in eco             <<= cleanTask,
            ecoGraph                 <<= ecoGraphTask,
            eco                      <<= compileTask
        )) ++ Seq(
            cleanFiles               <+=  resourceManaged in eco in conf,
            watchSources             <++= watchSources in eco in conf
        )
    }

    def ecoSettings: Seq[Setting[_]] =
        ecoSettingsIn(Compile) ++ ecoSettingsIn(Test)
}
import sbt._
import Keys._

import com.untyped.sbtgraph.{Graph,Source,Descendents}

import org.mozilla.javascript.tools.shell.Global
import org.mozilla.javascript.{Context,Scriptable,ScriptableObject,Callable,JavaScriptException}

import scala.collection.JavaConverters._

object LessPlugin extends sbt.Plugin {
    case class LessSource(graph: LessGraph, src: File) extends Source with Rhino {
        type S = LessSource
        type G = LessGraph

        protected val importRegex = """^\s*@import\s*(?:\(([a-z]+)\))?\s*"([^"]+)";.*$""".r

        protected def parseImport(line: String): Option[String] = {
            line match {
                case importRegex(_, path) if path.endsWith(".less") && !path.contains("@{") => Some(path)
                case _                                                                      => None
            }
        }

        lazy val parents: List[LessSource] = {
            for {
                line <- IO.readLines(src).toList
                path <- parseImport(line)
            } yield graph.getSource(path, this)
        }

        def isTemplated: Boolean = src.getPath.contains(".template")

        val compileFunction: String =
            """
            |function loadFile(originalHref, currentFileInfo, callback, env, modifyVars) {
            |    var href = less.modules.path.join(currentFileInfo.rootpath, originalHref);
            |    var newFileInfo = {rootpath: less.modules.path.dirname(href)};
            |
            |    try {
            |        var data = readFile(href);
            |        callback(null, data, href, newFileInfo);
            |    } catch (e) {
            |        callback(e, null, href);
            |    }
            |}
            |
            |less.Parser.fileLoader = loadFile;
            |
            |function compile(code, rootDir) {
            |    var options = {rootpath: rootDir, paths: [rootDir]};
            |    var css = null;
            |
            |    new less.Parser(options).parse(code, function (e, root) {
            |        if (e) { throw e; }
            |        css = root.toCSS({ compress: false });
            |    });
            |
            |    return css;
            |}
            """.trim.stripMargin

        def lessScope(ctx: Context): Scriptable = {
            val global = new Global()
            global.init(ctx)

            val scope = ctx.initStandardObjects(global)

            val lessScript = "less-rhino-1.7.0.js"
            val lessReader = new java.io.InputStreamReader(getClass.getResourceAsStream(lessScript))

            ctx.evaluateReader(scope, lessReader, lessScript, 1, null)
            ctx.evaluateString(scope, compileFunction, "<sbt>", 1, null)

            scope
        }

        def compile: Option[File] = {
            des.map { des =>
                graph.log.info(s"Compiling ${graph.pluginName} source $des")
                withContext { ctx =>
                    val scope = lessScope(ctx)
                    val lessCompiler = scope.get("compile", scope).asInstanceOf[Callable]
                    val args = Array[AnyRef](IO.read(src), src.getParent)
                    val output = withError { lessCompiler.call(ctx, scope, scope, args) }.toString
                    IO.write(des, output)
                    des
                }
            }
        }

        def withError[T](block: => T): T = {
            try {
                block
            } catch {
                case exception: JavaScriptException =>
                    val error   = exception.getValue.asInstanceOf[Scriptable]
                    val line    = ScriptableObject.getProperty(error, "line"   ).asInstanceOf[Double].intValue
                    val column  = ScriptableObject.getProperty(error, "column" ).asInstanceOf[Double].intValue
                    val message = ScriptableObject.getProperty(error, "message").toString
                    sys.error("%s error: %s [%s,%s]: %s".format(graph.pluginName, src.getName, line, column, message))
            }
        }
    }

    case class LessGraph(log: Logger, sourceDirs: Seq[File], targetDir: File) extends Graph {
        type S = LessSource

        val pluginName = "sbt-less"

        val templateProperties = null
        val downloadDir        = null

        def createSource(src: File): LessSource =
            LessSource(this, src.getCanonicalFile)

        def srcFilenameToDesFilename(filename: String) =
            filename.stripSuffix("less") + "css"
    }

    object LessKeys {
        val less = taskKey[Seq[File]]("Compile Less templates")
        val lessGraph = taskKey[LessGraph]("Collection of Less templates")
    }

    import LessKeys._

    def lessGraphTask = Def.task {
        val graph = LessGraph(
            log        = streams.value.log,
            sourceDirs = (sourceDirectories in less).value,
            targetDir  = (resourceManaged in less).value)

        (unmanagedSources in less).value.foreach(graph += _)
        graph
    }

    def unmanagedSourcesTask = Def.task {
        val include = includeFilter in less value
        val exclude = excludeFilter in less value

        (sourceDirectories in less).value.foldLeft(Seq[File]()) {
            (acc, sourceDir) => acc ++ Descendents(sourceDir, include, exclude).get
        }
    }

    def watchSourcesTask = Def.task {
        val graph = (lessGraph in less).value
        graph.sources.map(_.src): Seq[File]
    }

    def compileTask = Def.task {
        val sources = (unmanagedSources in less).value
        val graph = (lessGraph in less).value
        graph.compileAll(sources)
    }

    def cleanTask = Def.task {
        val graph = (lessGraph in less).value
        graph.sources.foreach(_.clean())
    }

    def lessSettingsIn(conf: Configuration): Seq[Setting[_]] = {
        inConfig(conf)(Seq(
            includeFilter in less     :=  "*.less",
            excludeFilter in less     :=  (".*" - ".") || "_*" || HiddenFileFilter,
            sourceDirectory in less   <<= (sourceDirectory in conf),
            sourceDirectories in less <<= (sourceDirectory in (conf, less)) { Seq(_) },
            unmanagedSources in less  <<= unmanagedSourcesTask,
            resourceManaged in less   <<= resourceManaged in conf,
            sources in less           <<= watchSourcesTask,
            watchSources in less      <<= watchSourcesTask,
            clean in less             <<= cleanTask,
            lessGraph                 <<= lessGraphTask,
            less                      <<= compileTask
        )) ++ Seq(
            cleanFiles                <+=  resourceManaged in less in conf,
            watchSources              <++= watchSources in less in conf
        )
    }

    def lessSettings: Seq[Setting[_]] =
        lessSettingsIn(Compile) ++ lessSettingsIn(Test)
}
import org.mozilla.javascript.Context

trait Rhino {
    def withContext[T](fn: Context => T): T = {
        val ctx = Context.enter()
        try {
            ctx.setOptimizationLevel(-1)
            ctx.setLanguageVersion(Context.VERSION_1_8)
            fn(ctx)
        } finally {
            Context.exit()
        }
    }
}


import sbt._

import scala.io.Source
import scala.collection.mutable
import scala.collection.JavaConverters._

import com.google.javascript.jscomp.{Compiler,CompilerOptions,SourceFile,VariableRenamingPolicy,NodeTraversal}
import com.google.javascript.rhino.Node

import org.jgrapht.experimental.dag.DirectedAcyclicGraph
import org.jgrapht.graph.DefaultEdge

object AST {
    object Call {
        def unapply(node: Node): Option[(String, List[Node])] = {
            if (node.isCall) {
                val fn :: args = node.children.asScala.toList
                Some((fn.getQualifiedName, args))
            } else
                None
        }
    }

    object Obj {
        def unapply(node: Node): Option[List[(String, Node)]] = {
            if (node.isObjectLit) {
                val keys = node.children().asScala.toList
                Some(keys.map { key =>
                    key.getString -> key.getFirstChild
                })
            } else
                None
        }
    }

    object Arr {
        def unapply(node: Node): Option[List[Node]] = {
            if (node.isArrayLit)
                Some(node.children().asScala.toList)
            else
                None
        }
    }

    object Str {
        def unapply(node: Node): Option[String] = {
            if (node.isString) Some(node.getString) else None
        }
    }
}

case class RequireJSSettings(
    baseUrl: File,
    mainConfigFile: File,
    name: String,
    include: List[String],
    wrapShim: Boolean,
    wrap: Option[(File, File)],
    out: File)

class RequireJS(log: Logger, settings: RequireJSSettings) {

    case class Shim(deps: List[String], exports: Option[String])

    case class Config(paths: Map[String, String], shim: Map[String, Shim])

    class ConfigReader extends NodeTraversal.Callback {
        import AST._

        val paths = mutable.Map.empty[String, String]
        val shim = mutable.Map.empty[String, Shim]

        def shouldTraverse(traversal: NodeTraversal, node: Node, parent: Node) = true

        def visit(traversal: NodeTraversal, node: Node, parent: Node) {
            node match {
                case Call("require.config", Obj(keys) :: Nil) =>
                    keys.foreach {
                        case ("paths", Obj(keys)) =>
                            paths ++= keys.collect {
                                case (name, Str(path)) => name -> path
                            }
                        case ("shim", Obj(keys)) =>
                            shim ++= keys.collect {
                                case (name, Obj(keys)) =>
                                    val deps = keys.collectFirst {
                                        case ("deps", Arr(deps)) =>
                                            deps.collect { case Str(dep) => dep }
                                    } getOrElse Nil

                                    val exports = keys.collectFirst {
                                        case ("exports", Str(exports)) => exports
                                    }

                                    name -> Shim(deps, exports)
                            }
                        case _ =>
                    }
                case _ =>
            }
        }
    }

    def readConfig: Config = {
        val compiler = new Compiler

        val input = SourceFile.fromFile(settings.mainConfigFile)
        val root = compiler.parse(input)

        val reader = new ConfigReader()
        val traversal = new NodeTraversal(compiler, reader)
        traversal.traverse(root)

        Config(reader.paths.toMap, reader.shim.toMap)
    }

    val config = readConfig

    def readFile(file: File): String = Source.fromFile(file).mkString

    def readResource(path: String): String = {
        val resource = getClass.getClassLoader.getResourceAsStream(path)
        Source.fromInputStream(resource).mkString
    }

    def getModule(name: String): File = {
        val path = name.split("/").toList match {
            case prefix :: suffix =>
                val canonicalPrefix = config.paths.get(prefix) getOrElse prefix
                canonicalPrefix :: suffix mkString("/")
            case _ =>
                name
        }

        new File(settings.baseUrl, path + ".js")
    }

    def readModule(name: String): String = readFile(getModule(name))

    def canonicalName(name: String, origin: String): String = {
        val nameParts = name.split("/").toList
        val parentParts = origin.split("/").toList.init

        val parts = if (name.startsWith("./")) {
            parentParts ++ nameParts.tail
        } else if (name.startsWith("../")) {
            if (parentParts.isEmpty) {
                sys.error(s"Can't reference $name from $origin")
            } else {
                parentParts.init ++ nameParts.tail
            }
        } else {
            nameParts
        }

        val canonicalName = parts.mkString("/")
        val moduleFile = getModule(canonicalName)

        if (moduleFile.exists) canonicalName
        else sys.error(s"Not found: ${moduleFile.getPath} (requested from $origin)")
    }

    class ModuleCollector(moduleName: String) extends NodeTraversal.Callback {
        import AST._

        val names = mutable.Set[String]()

        private var defineNode: Option[Node] = None

        private def updateDefine(node: Node) {
            if (defineNode.isDefined)
                sys.error(s"$moduleName defines multiple anonymous modules")
            else {
                val moduleNode = Node.newString(moduleName)
                node.addChildAfter(moduleNode, node.getFirstChild)
                defineNode = Some(node)
            }
        }

        private def suspiciousCall(node: Node) {
            val Call(name, _) = node
            log.warn(s"$moduleName#${node.getLineno}: suspicious call to $name()")
        }

        def shouldTraverse(traversal: NodeTraversal, node: Node, parent: Node) = true

        def visit(traversal: NodeTraversal, node: Node, parent: Node) {
            node match {
                case Call("require", args) => args match {
                    case Str(name) :: Nil =>
                        names += name
                    case _ =>
                        suspiciousCall(node)
                }
                case Call("define", args) => args match {
                    case Str(_) :: Arr(deps) :: _ :: Nil =>
                        names ++= deps.collect { case Str(name) => name }
                    case Arr(deps) :: _ :: Nil =>
                        updateDefine(node)
                        names ++= deps.collect { case Str(name) => name }
                    case Str(_) :: _ :: Nil =>
                        ()
                    case Str(_) :: Nil =>
                        ()
                    case _ :: Nil =>
                        updateDefine(node)
                    case _ =>
                        suspiciousCall(node)
                }
                case _ =>
            }
        }
    }

    case class Module(name: String, deps: Set[String], source: String) {
        def annotatedSource: String = {
            s"// module: $name\n${shimmedSource}"
        }

        def shimmedSource: String = {
            config.shim.get(name).map { shim =>
                val exports = shim.exports.map { name =>
                    s"\nreturn root.$name = $name;"
                } getOrElse ""
                val deps = this.deps.map(dep => s"'$dep'").mkString(", ")
                if (settings.wrapShim)
                    s"""
                    |(function(root) {
                    |    define("$name", [$deps], function() {
                    |        return (function() {
                    |            $source$exports
                    |        }).apply(root, arguments);
                    |    });
                    |}(this));
                    """.stripMargin.trim
                else
                    s"define('$name', [$deps], function() {\n$source$exports\n});"
            } getOrElse source
        }
    }

    val reservedNames = List("require", "module", "exports")

    def collectDependencies(name: String): Module = {
        val options = new CompilerOptions
        options.setLanguageIn(CompilerOptions.LanguageMode.ECMASCRIPT5)
        options.prettyPrint = true

        val compiler = new Compiler
        compiler.initOptions(options)

        log.debug(s"Parsing module $name")
        val input = SourceFile.fromFile(getModule(name))
        val root = compiler.parse(input)

        val collector = new ModuleCollector(name)
        val traversal = new NodeTraversal(compiler, collector)
        traversal.traverse(root)

        val deps = config.shim.get(name).map(_.deps.toSet) getOrElse {
            collector.names
                .filterNot(reservedNames contains _)
                .map(canonicalName(_, name))
                .toSet
        }

        val source = {
            val cb = new Compiler.CodeBuilder()
            compiler.toSource(cb, 1, root)
            cb.toString
        }

        Module(name, deps, source)
    }

    def collectModules(): List[Module] = {
        val visited = mutable.Set[String]()
        val pending = mutable.Set[String](settings.include: _*)
        val modules = mutable.ListBuffer[Module]()

        while (pending.nonEmpty) {
            val name = pending.head
            pending.remove(name)
            val module = collectDependencies(name)
            visited += name
            modules += module
            pending ++= module.deps -- visited
        }

        modules.toList
    }

    def sortModules(modules: List[Module]): List[Module] = {
        val graph = new DirectedAcyclicGraph[String, DefaultEdge](classOf[DefaultEdge])
        modules.map(_.name).foreach(graph.addVertex)

        for {
            module <- modules
            dependency <- module.deps
        } try {
            graph.addEdge(dependency, module.name)
        } catch {
            case _: IllegalArgumentException =>
                log.warn(s"${module.name} depending on $dependency introduces a cycle")
        }

        val modulesMap = modules.map(module => (module.name, module)).toMap
        graph.iterator.asScala.toList.map(modulesMap(_))
    }

    def minify(input: String): String = {
        val compiler = new Compiler
        val externs = Nil: List[SourceFile]
        val sources = SourceFile.fromCode(settings.baseUrl.getPath, input) :: Nil
        val options = new CompilerOptions
        options.setLanguageIn(CompilerOptions.LanguageMode.ECMASCRIPT5)
        options.variableRenaming = VariableRenamingPolicy.ALL
        options.prettyPrint = false
        val result = compiler.compile(externs.asJava, sources.asJava, options)
        if (result.errors.nonEmpty) {
            result.errors.foreach(error => log.error(error.toString))
            sys.error(s"${result.errors.length} errors found")
        } else {
            compiler.toSource
        }
    }

    def wrap(input: String): String = {
        settings.wrap.map { case (start, end) =>
            List(readFile(start), input, readFile(end)).mkString("\n")
        } getOrElse input
    }

    def moduleLoader: Module = {
        val source = readModule(settings.name)
        val define = s"define('${settings.name}', function(){});"
        Module(settings.name, Set.empty, s"$source\n$define")
    }

    def optimize: String = {
        val modules = sortModules(collectModules)
        val contents = (moduleLoader :: modules).map(_.annotatedSource)
        log.info(s"Collected ${modules.length+1} requirejs modules")
        wrap(contents mkString "\n")
    }

    def optimizeAndMinify: (String, String) = {
        val output = optimize
        (output, minify(output))
    }
}


package io.continuum.bokeh

import scala.annotation.StaticAnnotation
import scala.reflect.macros.Context

trait EnumType {
    val name: String = toString
}

trait LowerCase { self: EnumType =>
    override val name = toString.toLowerCase
}

trait UpperCase { self: EnumType =>
    override val name = toString.toUpperCase
}

trait SnakeCase { self: EnumType =>
    override val name = Utils.snakify(toString)
}

trait DashCase { self: EnumType =>
    override val name = Utils.snakify(toString, '-')
}

trait Enumerated[T <: EnumType] {
    type ValueType = T

    val values: Set[T]
    val fromString: PartialFunction[String, T]

    final def unapply(name: String): Option[T] = fromString.lift(name)

    override def toString: String = {
        val name = getClass.getSimpleName.stripSuffix("$")
        s"$name(${values.map(_.name).mkString(", ")})"
    }
}

class enum extends StaticAnnotation {
    def macroTransform(annottees: Any*): Any = macro EnumImpl.enumTransformImpl
}

private object EnumImpl {
    def enumTransformImpl(c: Context)(annottees: c.Expr[Any]*): c.Expr[Any] = {
        import c.universe._

        annottees.map(_.tree) match {
            case ModuleDef(mods, name, tpl @ Template(parents, sf, body)) :: Nil =>
                val enumImpl = reify { EnumImpl }
                val methods = List(
                    q"final val values: Set[ValueType] = $enumImpl.values[ValueType]",
                    q"final val fromString: PartialFunction[String, ValueType] = $enumImpl.fromString[ValueType]")
                val module = ModuleDef(mods, name, Template(parents, sf, body ++ methods))
                c.Expr[Any](Block(module :: Nil, Literal(Constant(()))))
            case _ => c.abort(c.enclosingPosition, "@enum annotation can only be applied to an object")
        }
    }

    private def children[T <: EnumType : c.WeakTypeTag](c: Context): Set[c.universe.Symbol] = {
        import c.universe._

        val tpe = weakTypeOf[T]
        val cls = tpe.typeSymbol.asClass

        if (!cls.isSealed) c.error(c.enclosingPosition, "must be a sealed trait or class")
        val children = tpe.typeSymbol.asClass.knownDirectSubclasses.filter(_.isModuleClass)
        if (children.isEmpty) c.error(c.enclosingPosition, "no enumerations found")

        children
    }

    def values[T <: EnumType]: Set[T] = macro EnumImpl.valuesImpl[T]

    def valuesImpl[T <: EnumType : c.WeakTypeTag](c: Context): c.Expr[Set[T]] = {
        import c.universe._

        val tpe = weakTypeOf[T]
        val values = children[T](c).map(_.name.toTermName)

        c.Expr[Set[T]](q"Set[$tpe](..$values)")
    }

    def fromString[T <: EnumType]: PartialFunction[String, T] = macro EnumImpl.fromStringImpl[T]

    def fromStringImpl[T <: EnumType : c.WeakTypeTag](c: Context): c.Expr[PartialFunction[String, T]] = {
        import c.universe._

        val tpe = weakTypeOf[T]
        val cases = children[T](c).map { child => cq"${child.name.toTermName}.name => ${child.name.toTermName}" }

        c.Expr[PartialFunction[String, T]](q"{ case ..$cases }: PartialFunction[String, $tpe]")
    }
}


package io.continuum.bokeh

import scala.reflect.macros.Context

import play.api.libs.json.JsValue

trait AbstractField {
    type ValueType

    def valueOpt: Option[ValueType]
    def value: ValueType

    def set(value: Option[ValueType])

    def toJson: Option[JsValue]
}

case class FieldRef(name: String, field: AbstractField)

object Fields {
    def fields[T](obj: T): List[FieldRef] = macro fieldsImpl[T]

    def fieldsImpl[T: c.WeakTypeTag](c: Context)(obj: c.Expr[T]): c.Expr[List[FieldRef]] = {
        import c.universe._

        val refs = weakTypeOf[T].members
            .filter(_.isModule)
            .map(_.asModule)
            .filter(_.typeSignature <:< typeOf[AbstractField])
            .map { member =>
                q"FieldRef(${member.name.decoded}, $obj.${member.name.toTermName})"
            }

        c.Expr[List[FieldRef]](q"List(..$refs)")
    }
}


package io.continuum.bokeh

import scala.annotation.StaticAnnotation
import scala.reflect.macros.Context

private object ModelImpl {
    def macroTransformImpl(c: Context)(annottees: c.Expr[Any]*): c.Expr[Any] = {
        import c.universe._

        annottees.map(_.tree) match {
            case ClassDef(mods, name, tparams, tpl @ Template(parents, sf, body)) :: companion =>
                val expandedBody = body.flatMap {
                    case q"$prefix = include[$mixin]" =>
                        // XXX: should be c.typecheck(tq"$mixin", c.TYPEMODE)
                        val tpe = c.typeCheck(q"null: $mixin").tpe

                        val fields = tpe.members
                            .filter(_.isModule)
                            .map(_.asModule)
                            .filter(_.typeSignature <:< typeOf[AbstractField])

                        fields.map { field =>
                            val name = newTermName(s"${prefix}_${field.name}")
                            val sig = field.typeSignature
                            val tpe = sig.member(newTypeName("ValueType")).typeSignatureIn(sig)
                            // TODO: add support for precise field type (Vectorized, NonNegative, etc.)
                            q"object $name extends Field[$tpe]"
                        }
                    case field => field :: Nil
                }

                val bokeh = q"io.continuum.bokeh"
                val methods = List(q"""override def fields: List[$bokeh.FieldRef] = $bokeh.Fields.fields(this)""")

                val decl = ClassDef(mods, name, tparams, Template(parents, sf, expandedBody ++ methods))
                c.Expr[Any](Block(decl :: companion, Literal(Constant(()))))
            case _ => c.abort(c.enclosingPosition, "expected a class")
        }
    }
}

class model extends StaticAnnotation {
    def macroTransform(annottees: Any*): Any = macro ModelImpl.macroTransformImpl
}


package io.continuum.bokeh

object Utils {
    def uuid4(): String = java.util.UUID.randomUUID.toString

    def snakify(name: String, sep: Char = '_'): String =
        name.replaceAll("([A-Z]+)([A-Z][a-z])", s"$$1$sep$$2")
            .replaceAll("([a-z\\d])([A-Z])", s"$$1$sep$$2")
            .toLowerCase
}
