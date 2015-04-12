package io.continuum.bokeh

import java.io.File
import java.awt.Desktop

import scalax.io.JavaConverters._
import scalax.file.Path

import scala.collection.mutable.ListBuffer
import scala.xml.{Node,NodeSeq,XML}

class Document(objs: Widget*) {
    private val objects = ListBuffer[Widget](objs: _*)

    def add(objs: Widget*) {
        objects ++= objs
    }

    def fragment(resources: Resources): HTMLFragment = HTMLFragmentWriter(objs.toList, resources).write()
    def fragment(): HTMLFragment = fragment(Resources.default)

    def save(file: File, resources: Resources): HTMLFile = HTMLFileWriter(objs.toList, resources).write(file)
    def save(file: File): HTMLFile = save(file, Resources.default)

    def save(path: String, resources: Resources): HTMLFile = save(new File(path), resources)
    def save(path: String): HTMLFile = save(new File(path))
}

class HTMLFragment(val html: NodeSeq, val styles: NodeSeq, val scripts: NodeSeq) {
    def head: NodeSeq = styles ++ scripts
    def logo: NodeSeq = {
        <div>
            <a href="http://bokeh.pydata.org" target="_blank" class="bk-logo bk-logo-small bk-logo-notebook"></a>
            <span>BokehJS successfully loaded.</span>
        </div>
    }
    def preamble: NodeSeq = head ++ logo
}

object HTMLFragmentWriter {
    def apply(obj: Widget): HTMLFragmentWriter = apply(obj, Resources.default)

    def apply(obj: Widget, resources: Resources): HTMLFragmentWriter = apply(obj :: Nil, resources)

    def apply(objs: List[Widget]): HTMLFragmentWriter = apply(objs, Resources.default)

    def apply(objs: List[Widget], resources: Resources): HTMLFragmentWriter = {
        val contexts = objs.map(obj => new PlotContext().children(obj :: Nil))
        new HTMLFragmentWriter(contexts, resources)
    }
}

class HTMLFragmentWriter(contexts: List[PlotContext], resources: Resources) {
    protected val serializer = new JSONSerializer(resources.stringify _)

    def write(): HTMLFragment = {
        new HTMLFragment(renderPlots(plotSpecs), resources.styles, resources.scripts)
    }

    protected case class PlotSpec(models: String, modelRef: Ref, elementId: String) {
        def modelId = modelRef.id
        def modelType = modelRef.`type`
    }

    protected def plotSpecs: List[PlotSpec] = {
        contexts.map { context =>
            val models = serializer.stringify(context)
            PlotSpec(models, context.getRef, IdGenerator.next())
        }
    }

    protected def renderPlots(specs: List[PlotSpec]): NodeSeq = {
        specs.flatMap { spec =>
            <div>
                <div class="plotdiv" id={ spec.elementId }></div>
                { renderPlot(spec) }
            </div>
        }
    }

    protected def renderPlot(spec: PlotSpec): xml.Node = {
        val code = s"""
            |Bokeh.set_log_level("${resources.logLevel.name}")
            |var models = ${spec.models};
            |var modelid = "${spec.modelId}";
            |var modeltype = "${spec.modelType}";
            |var elementid = "#${spec.elementId}";
            |Bokeh.logger.info("Realizing plot:")
            |Bokeh.logger.info(" - modeltype: " + modeltype);
            |Bokeh.logger.info(" - modelid:   " + modelid);
            |Bokeh.logger.info(" - elementid: " + elementid);
            |Bokeh.load_models(models);
            |var model = Bokeh.Collections(modeltype).get(modelid);
            |var view = new model.default_view({model: model, el: elementid});
            """
        resources.wrap(code.stripMargin.trim).asScript
    }
}

class HTMLFile(val file: File) {
    def url: String = {
        val uri = file.toURI
        s"${uri.getScheme}://${uri.getSchemeSpecificPart}"
    }

    def view() {
        if (Desktop.isDesktopSupported && Desktop.getDesktop.isSupported(Desktop.Action.BROWSE))
            Desktop.getDesktop.browse(file.toURI)
    }
}

object HTMLFileWriter {
    def apply(obj: Widget): HTMLFileWriter = apply(obj, Resources.default)

    def apply(obj: Widget, resources: Resources): HTMLFileWriter = apply(obj :: Nil, resources)

    def apply(objs: List[Widget]): HTMLFileWriter = apply(objs, Resources.default)

    def apply(objs: List[Widget], resources: Resources): HTMLFileWriter = {
        val contexts = objs.map(obj => new PlotContext().children(obj :: Nil))
        new HTMLFileWriter(contexts, resources)
    }
}

class HTMLFileWriter(contexts: List[PlotContext], resources: Resources) extends HTMLFragmentWriter(contexts, resources) {
    def write(file: File): HTMLFile = {
        val html = stringify(renderFile(write()))
        Path(file).write(html)
        new HTMLFile(file)
    }

    protected def stringify(html: Node) = {
        val writer = new java.io.StringWriter()
        val doctype = "<!DOCTYPE html>"
        XML.write(writer, html, "UTF-8", xmlDecl=false, doctype=null)
        s"$doctype\n${writer.toString}"
    }

    protected def renderTitle: Option[Node] = {
        contexts.flatMap(_.children.value)
                .collectFirst { case plot: Plot => plot.title.value }
                .map { title => <title>{title}</title> }
    }

    protected def renderFile(fragment: HTMLFragment): Node = {
        <html lang="en">
            <head>
                <meta charset="utf-8" />
                { renderTitle orNull }
                { fragment.styles }
                { fragment.scripts }
            </head>
            <body>
                { fragment.html }
            </body>
        </html>
    }
}

case class FontSize(value: Double, units: FontUnits) {
    def toCSS = s"$value${units.name}"
}
package io.continuum.bokeh

trait IdGenerator {
    def next(): String
}

object UUIDGenerator extends IdGenerator {
    def next() = Utils.uuid4()
}

object CounterGenerator extends IdGenerator {
    private var counter = 0

    def next() = synchronized {
        val id = counter
        counter += 1
        id.toString
    }
}

object IdGenerator {
    private var implementation: Option[IdGenerator] = None

    def setImplementation(impl: IdGenerator, silent: Boolean=false) {
        implementation match {
            case Some(_) => if (!silent) throw new IllegalStateException("ID generator was already configured")
            case None    => implementation = Some(impl)
        }
    }

    def next(): String = {
        implementation getOrElse UUIDGenerator next()
    }
}


package io.continuum.bokeh

import scala.reflect.ClassTag

import scala.collection.immutable.NumericRange
import breeze.linalg.{DenseVector,DenseMatrix}

object LinAlg extends LinAlg
trait LinAlg {
    def meshgrid(x1: DenseVector[Double], x2: DenseVector[Double]): (DenseMatrix[Double], DenseMatrix[Double]) = {
        val x1Mesh = DenseMatrix.zeros[Double](x2.length, x1.length)
        for (i <- 0 until x2.length) {
            x1Mesh(i, ::) := x1.t
        }
        val x2Mesh = DenseMatrix.zeros[Double](x2.length, x1.length)
        for (i <- 0 until x1.length) {
            x2Mesh(::, i) := x2
        }
        (x1Mesh, x2Mesh)
    }

    implicit def NumericRangeToDenseVector[T:ClassTag](range: NumericRange[T]) = new DenseVector(range.toArray)
}


package io.continuum.bokeh

trait FillProps { self: HasFields with Vectorization =>
    object fill_color extends Vectorized[Color](Color.Gray)
    object fill_alpha extends Vectorized[Percent]
}

trait LineProps { self: HasFields with Vectorization =>
    object line_color extends Vectorized[Color](Color.Black)
    object line_width extends Vectorized[Double](1.0)
    object line_alpha extends Vectorized[Percent]
    object line_join extends Vectorized[LineJoin]
    object line_cap extends Vectorized[LineCap]
    object line_dash extends Vectorized[List[Int]]
    object line_dash_offset extends Vectorized[Int]
}

trait TextProps { self: HasFields with Vectorization =>
    object text_font extends Vectorized[String]
    object text_font_size extends Vectorized[FontSize](10 pt)
    object text_font_style extends Vectorized[FontStyle]
    object text_color extends Vectorized[Color](Color.Black)
    object text_alpha extends Vectorized[Percent]
    object text_align extends Vectorized[TextAlign]
    object text_baseline extends Vectorized[TextBaseline]
}


package io.continuum.bokeh

import java.io.File
import java.net.URL

trait NodeImplicits {
    implicit class StringNode(script: String) {
        def asScript: xml.Node = {
            <script type="text/javascript">{xml.Unparsed(s"""
            // <![CDATA[
            $script
            // ]]>
            """)}</script>
        }

        def asStyle: xml.Node = {
            <style>{xml.Unparsed(s"""
            $script
            """)}</style>
        }
    }

    implicit class FileNode(file: File) {
        def asScript: xml.Node = {
            <script type="text/javascript" src={file.getPath}></script>
        }

        def asStyle: xml.Node = {
            <link rel="stylesheet" href={file.getPath}></link>
        }
    }

    implicit class URLNode(url: URL) {
        def asScript: xml.Node = {
            <script type="text/javascript" src={url.toString}></script>
        }

        def asStyle: xml.Node = {
            <link rel="stylesheet" href={url.toString}></link>
        }
    }
}


package io.continuum.bokeh

import java.io.File
import java.net.URL
import java.util.Properties

import scalax.io.JavaConverters._
import scalax.file.Path

import play.api.libs.json.{Json,JsValue}

sealed trait Resources {
    def scripts: List[xml.Node]
    def styles: List[xml.Node]

    def wrap(code: String): String = {
        s"(function() {\n$code\n})();"
    }

    def stringify(value: JsValue): String = {
        Json.stringify(value)
    }

    def logLevel: LogLevel = LogLevel.Info

    protected def getResource(path: String): URL = {
        getClass.getClassLoader.getResource(path)
    }

    protected def loadResource(path: String): String = {
        getResource(path).asInput.chars.mkString
    }
}

object Resources {
    val bokehjsVersion: String = {
        val stream = getClass.getClassLoader.getResourceAsStream("bokehjs.properties")
        try {
            val props = new java.util.Properties()
            props.load(stream)
            props.getProperty("bokehjs.version")
        } finally {
            stream.close()
        }
    }

    private def resource(ext: String, version: Boolean=false, minified: Boolean=false) =
        s"bokeh${if (version) "-" + bokehjsVersion else ""}${if (minified) ".min" else ""}.$ext"

    private val jsMin = resource("js", minified=true)
    private val jsUnMin = resource("js")

    private val cssMin = resource("css", minified=true)
    private val cssUnMin = resource("css")

    trait InlineResources extends Resources {
        def inlineJS(path: String): xml.Node = loadResource("js/" + path).asScript
        def inlineCSS(path: String): xml.Node = loadResource("css/" + path).asStyle
    }

    case object Inline extends InlineResources {
        def scripts = inlineJS(jsUnMin) :: Nil
        def styles = inlineCSS(cssUnMin) :: Nil
    }

    case object InlineMin extends InlineResources {
        def scripts = inlineJS(jsMin) :: Nil
        def styles = inlineCSS(cssMin) :: Nil
    }

    trait ExternalResources extends Resources {
        def includeJS(path: String): xml.Node
        def includeCSS(path: String): xml.Node
    }

    trait ExternalFileResources extends ExternalResources {
        def resolveFile(file: File): File

        def getFile(path: String): File = {
            val resource = getResource(path)
            resource.getProtocol match {
                case "file"   => resolveFile(new File(resource.getPath))
                case protocol => sys.error(s"unable to load $path due to invalid protocol: $protocol")
            }
        }

        def baseJSDir: File = getFile("js")
        def baseCSSDir: File = getFile("css")

        def includeJS(path: String): xml.Node = new File(baseJSDir, path).asScript
        def includeCSS(path: String): xml.Node = new File(baseCSSDir, path).asStyle
    }

    trait RelativeResources { self: ExternalFileResources =>
        private val rootDir = new File(System.getProperty("user.dir"))
        def resolveFile(file: File): File = new File(rootDir.toURI.relativize(file.toURI).getPath)
    }

    trait AbsoluteResources { self: ExternalFileResources =>
        def resolveFile(file: File): File = file
    }

    case object Relative extends ExternalFileResources with RelativeResources {
        def scripts = includeJS(jsUnMin) :: Nil
        def styles = includeCSS(cssUnMin) :: Nil
    }

    case object RelativeMin extends ExternalFileResources with RelativeResources {
        def scripts = includeJS(jsMin) :: Nil
        def styles = includeCSS(cssMin) :: Nil
    }

    case object Absolute extends ExternalFileResources with AbsoluteResources {
        def scripts = includeJS(jsUnMin) :: Nil
        def styles = includeCSS(cssUnMin) :: Nil
    }

    case object AbsoluteMin extends ExternalFileResources with AbsoluteResources {
        def scripts = includeJS(jsMin) :: Nil
        def styles = includeCSS(cssMin) :: Nil
    }

    trait DevelopmentResources extends ExternalFileResources {
        def requireConfig: xml.Node = {
            s"require.config({ baseUrl: 'file://$baseJSDir' });".asScript
        }

        def scripts =
            includeJS("vendor/requirejs/require.js") ::
            includeJS("config.js") ::
            requireConfig ::
            Nil

        def styles =
            includeCSS(cssUnMin) ::
            Nil

        override def wrap(code: String): String = {
            val wrapped = super.wrap(code)
            s"require(['jquery', 'main'], function($$, Bokeh) {\n$wrapped\n});"
        }

        override def logLevel: LogLevel = LogLevel.Debug

        override def stringify(value: JsValue): String = {
            Json.prettyPrint(value)
        }
    }

    case object RelativeDev extends DevelopmentResources with RelativeResources
    case object AbsoluteDev extends DevelopmentResources with AbsoluteResources

    abstract class Remote(url: URL) extends ExternalResources {
        def includeJS(path: String): xml.Node = new URL(url, "/" + path).asScript
        def includeCSS(path: String): xml.Node = new URL(url, "/" + path).asStyle

        def scripts = includeJS(resource("js", true, true)) :: Nil
        def styles = includeCSS(resource("css", true, true)) :: Nil
    }

    case object CDN extends Remote(new URL("http://cdn.pydata.org"))

    private val fromStringPF: PartialFunction[String, Resources] = {
        case "cdn"          => CDN
        case "inline"       => Inline
        case "inline-min"   => InlineMin
        case "relative"     => Relative
        case "relative-min" => RelativeMin
        case "relative-dev" => RelativeDev
        case "absolute"     => Absolute
        case "absolute-min" => AbsoluteMin
        case "absolute-dev" => AbsoluteDev
    }

    def fromString(string: String): Option[Resources] = fromStringPF.lift(string)

    val default = InlineMin
}


package io.continuum.bokeh

import play.api.libs.json.{Json,JsValue,JsArray,JsObject,JsString}

class JSONSerializer(val stringifyFn: JsValue => String) {
    case class Model(id: String, `type`: String, attributes: JsObject, doc: Option[String] = None)

    implicit val ModelFormat = Json.format[Model]

    def getModel(obj: PlotObject): Model = {
        val Ref(id, tp) = obj.getRef
        Model(id, tp, HasFieldsWrites.writeFields(obj))
    }

    def stringify(obj: PlotObject): String = {
        serializeObjs(collectObjs(obj))
    }

    def serializeObjs(objs: List[PlotObject]): String = {
        stringifyFn(Json.toJson(objs.map(getModel)))
    }

    def collectObjs(obj: HasFields): List[PlotObject] = {
        val objs = collection.mutable.ListBuffer[PlotObject]()

        traverse(obj, obj => obj match {
            case _: PlotObject => objs += obj
            case _ =>
        })

        objs.toList
    }

    def traverse(obj: HasFields, fn: PlotObject => Unit) {
        val ids = collection.mutable.HashSet[String]()

        def descendFields(obj: HasFields) {
            obj.fields.map(_.field.valueOpt).foreach(_.foreach(descend _))
        }

        def descend(obj: Any) {
            obj match {
                case obj: PlotObject =>
                    if (!ids.contains(obj.id.value)) {
                        ids += obj.id.value
                        descendFields(obj)
                        fn(obj)
                    }
                case obj: HasFields =>
                    descendFields(obj)
                case obj: List[_] =>
                    obj.foreach(descend)
                case obj: Map[_, _] =>
                    obj.foreach { case (key, value) => descend(key) -> descend(value) }
                case obj: Product =>
                    obj.productIterator.foreach(descend)
                case _ =>
            }
        }

        descend(obj)
    }
}


package io.continuum.bokeh

trait Toolset { toolset =>
    protected val tools: List[DefaultTool]
    def |(other: DefaultTool) = new Toolset { val tools = toolset.tools :+ other }
    def toList: List[Tool] = tools.map(_.tool)
}

sealed abstract class DefaultTool extends Toolset {
    protected val tools = this :: Nil
    def tool: Tool
}

trait Tools {
    case object Pan extends DefaultTool                { def tool = new PanTool()                }
    case object WheelZoom extends DefaultTool          { def tool = new WheelZoomTool()          }
    case object PreviewSave extends DefaultTool        { def tool = new PreviewSaveTool()        }
    case object Reset extends DefaultTool              { def tool = new ResetTool()              }
    case object Resize extends DefaultTool             { def tool = new ResizeTool()             }
    case object Tap extends DefaultTool                { def tool = new TapTool()                }
    case object Crosshair extends DefaultTool          { def tool = new CrosshairTool()          }
    case object BoxZoom extends DefaultTool            { def tool = new BoxZoomTool()            }
    case object BoxSelect extends DefaultTool          { def tool = new BoxSelectTool()          }
    case object Hover extends DefaultTool              { def tool = new HoverTool()              }

    implicit def ToolsetToList(tools: Toolset): List[Tool] = tools.toList
}

object Tools extends Tools


package io.continuum.bokeh

sealed trait Tooltip
case class StringTooltip(string: String) extends Tooltip
case class HTMLTooltip(html: xml.NodeSeq) extends Tooltip
case class TabularTooltip(rows: List[(String, String)]) extends Tooltip
object Tooltip {
    def apply(string: String) = StringTooltip(string)
    def apply(html: xml.NodeSeq) = HTMLTooltip(html)
    def apply(rows: (String, String)*) = TabularTooltip(rows.toList)
    def apply(rows: List[(String, String)]) = TabularTooltip(rows)
}


package io.continuum.bokeh

case class Validator[T](fn: T => Boolean, message: String)

trait ValidableField { self: AbstractField =>
    def validators: List[Validator[ValueType]] = Nil

    def validate(value: ValueType): List[String] = {
        validators.filterNot(_.fn(value)).map(_.message)
    }

    def validates(value: ValueType) {
        validate(value) match {
            case error :: _ => throw new ValueError(error)
            case Nil =>
        }
    }
}


package io.continuum.bokeh

trait NonNegative extends ValidableField { self: HasFields#Field[Double] =>
    abstract override def validators = {
        Validator[Double](_ >= 0, "value must be non-negative") :: super.validators
    }
}



package io.continuum.bokeh

import scala.reflect.ClassTag

import play.api.libs.json.{Json,Writes,JsValue,JsString,JsNumber,JsArray,JsObject,JsNull}
import org.joda.time.{DateTime,LocalTime=>Time,LocalDate=>Date}
import breeze.linalg.DenseVector

trait PrimitiveWrites {
    implicit object CharWrites extends Writes[Char] {
        def writes(c: Char) = JsString(c.toString)
    }
}

trait MapWrites {
    implicit def StringMapWrites[V:Writes]: Writes[Map[String, V]] = new Writes[Map[String, V]] {
        def writes(obj: Map[String, V]) =
            JsObject(obj.map { case (k, v) => (k, implicitly[Writes[V]].writes(v)) } toSeq)
    }

    implicit def EnumTypeMapWrites[E <: EnumType:Writes, V:Writes]: Writes[Map[E, V]] = new Writes[Map[E, V]] {
        def writes(obj: Map[E, V]) = {
            JsObject(obj.map { case (k, v) => (k.name, implicitly[Writes[V]].writes(v)) } toSeq)
        }
    }
}

trait TupleWrites {
    implicit def Tuple2Writes[T1:Writes, T2:Writes]: Writes[(T1, T2)] = new Writes[(T1, T2)] {
        def writes(t: (T1, T2)) = JsArray(List(implicitly[Writes[T1]].writes(t._1),
                                               implicitly[Writes[T2]].writes(t._2)))
    }

    implicit def Tuple3Writes[T1:Writes, T2:Writes, T3:Writes]: Writes[(T1, T2, T3)] = new Writes[(T1, T2, T3)] {
        def writes(t: (T1, T2, T3)) = JsArray(List(implicitly[Writes[T1]].writes(t._1),
                                                   implicitly[Writes[T2]].writes(t._2),
                                                   implicitly[Writes[T3]].writes(t._3)))
    }
}

trait DateTimeWrites {
    implicit val DateTimeJSON = new Writes[DateTime] {
        def writes(datetime: DateTime) = JsNumber(datetime.getMillis)
    }

    implicit val TimeJSON = new Writes[Time] {
        def writes(time: Time) = JsNumber(time.getMillisOfDay)
    }

    implicit val DateJSON = new Writes[Date] {
        def writes(date: Date) = implicitly[Writes[DateTime]].writes(date.toDateTimeAtStartOfDay)
    }
}

trait BokehWrites {
    implicit def DenseVectorWrites[T:Writes:ClassTag] = new Writes[DenseVector[T]] {
        def writes(vec: DenseVector[T]) =
            implicitly[Writes[Array[T]]].writes(vec.toArray)
    }

    implicit val SymbolWrites = new Writes[Symbol] {
        def writes(symbol: Symbol) = JsString(symbol.name)
    }

    implicit val PercentWrites = new Writes[Percent] {
        def writes(percent: Percent) =
            implicitly[Writes[Double]].writes(percent.value)
    }

    implicit val ColorWrites = new Writes[Color] {
        def writes(color: Color) = JsString(color.toCSS)
    }

    implicit val FontSizeWrites = new Writes[FontSize] {
        def writes(size: FontSize) = JsString(size.toCSS)
    }

    implicit val TooltipWrites = new Writes[Tooltip] {
        def writes(tooltip: Tooltip) = tooltip match {
            case StringTooltip(string) => Json.toJson(string)
            case HTMLTooltip(html)     => Json.toJson(html.toString)
            case TabularTooltip(rows)  => Json.toJson(rows)
        }
    }

    implicit def EnumWrites[T <: EnumType] = new Writes[T] {
        def writes(value: T) = implicitly[Writes[String]].writes(value.name)
    }

    implicit object OrientationWrites extends Writes[Orientation] {
        def writes(value: Orientation) = value match {
            case Orientation.Angle(value) => Json.toJson(value)
            case _                        => implicitly[Writes[EnumType]].writes(value)
        }
    }

    implicit val RefWrites = Json.writes[Ref]

    implicit def FieldWrites[T:Writes] = new Writes[AbstractField { type ValueType = T }] {
        def writes(obj: AbstractField { type ValueType = T }) =
            implicitly[Writes[Option[T]]].writes(obj.valueOpt)
    }

    implicit object HasFieldsWrites extends Writes[HasFields] {
        def writeFields(obj: HasFields): JsObject = {
            val fields = obj.fields
               .map { case FieldRef(name, field) => (name, field.toJson) }
               .collect { case (name, Some(jsValue)) => (name, jsValue) }
            JsObject(fields) + ("type" -> JsString(obj.typeName))
        }

        def writes(obj: HasFields) = obj match {
            case obj: PlotObject => implicitly[Writes[Ref]].writes(obj.getRef)
            case _               => writeFields(obj)
        }
    }

    implicit object SymbolAnyMapWrites extends Writes[Map[Symbol, Any]] {
        private def seqToJson(obj: TraversableOnce[_]): JsValue = {
            JsArray(obj.toIterator.map(anyToJson).toSeq)
        }

        private def anyToJson(obj: Any): JsValue = obj match {
            case obj: Boolean            => Json.toJson(obj)
            case obj: Byte               => Json.toJson(obj)
            case obj: Short              => Json.toJson(obj)
            case obj: Int                => Json.toJson(obj)
            case obj: Long               => Json.toJson(obj)
            case obj: Float              => Json.toJson(obj)
            case obj: Double             => Json.toJson(obj)
            case obj: Char               => Json.toJson(obj)
            case obj: String             => Json.toJson(obj)
            case obj: Color              => Json.toJson(obj)
            case obj: Percent            => Json.toJson(obj)
            case obj: EnumType           => Json.toJson(obj)
            case obj: DateTime           => Json.toJson(obj)
            case obj: Time               => Json.toJson(obj)
            case obj: Date               => Json.toJson(obj)
            case obj: Option[_]          => obj.map(anyToJson) getOrElse JsNull
            case obj: Array[_]           => seqToJson(obj)
            case obj: TraversableOnce[_] => seqToJson(obj)
            case obj: DenseVector[_]     => seqToJson(obj.valuesIterator)
            case _ => throw new IllegalArgumentException(s"$obj of type <${obj.getClass}>")
        }

        def writes(obj: Map[Symbol, Any]) = {
            JsObject(obj.map { case (k, v) => (k.name, anyToJson(v)) } toList)
        }
    }
}

trait Formats extends PrimitiveWrites with MapWrites with TupleWrites with DateTimeWrites with BokehWrites
object Formats extends Formats




package object bokeh extends Formats with NodeImplicits with SourceImplicits {
    implicit class NumbericOps[T:Numeric](value: T) {
        def %% : Percent = Percent(implicitly[Numeric[T]].toDouble(value)/100)

        def ex: FontSize = FontSize(implicitly[Numeric[T]].toDouble(value), FontUnits.EX)
        def px: FontSize = FontSize(implicitly[Numeric[T]].toDouble(value), FontUnits.PX)
        def cm: FontSize = FontSize(implicitly[Numeric[T]].toDouble(value), FontUnits.CM)
        def mm: FontSize = FontSize(implicitly[Numeric[T]].toDouble(value), FontUnits.MM)
        def in: FontSize = FontSize(implicitly[Numeric[T]].toDouble(value), FontUnits.IN)
        def pt: FontSize = FontSize(implicitly[Numeric[T]].toDouble(value), FontUnits.PT)
        def pc: FontSize = FontSize(implicitly[Numeric[T]].toDouble(value), FontUnits.PC)
    }

    implicit def NumbericToPercent[T:Numeric](value: T): Percent = {
        Percent(implicitly[Numeric[T]].toDouble(value))
    }

    implicit def NumbericToOrientation[T:Numeric](value: T): Orientation.Angle = {
        Orientation.Angle(implicitly[Numeric[T]].toDouble(value))
    }

    implicit class BooleanOps(val bool: Boolean) extends AnyVal {
        final def option[A](value: => A): Option[A] = if (bool) Some(value) else None
    }

    implicit class ListOps[T](list: List[T]) {
        def *(n: Int): List[T] = (0 until n).flatMap(_ => list).toList
    }
}


