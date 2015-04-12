
import scopt.{OptionParser,Read}

private object CustomReads {
    implicit val resourcesReads: Read[Resources] = Read.reads { string =>
        Resources.fromString(string) getOrElse {
            throw new IllegalArgumentException(s"'$string' is not a valid resource mode.")
        }
    }
}

trait Example extends App {
    case class Config(resources: Resources = Resources.default, quiet: Boolean = false)

    def config: Config = _config
    private var _config: Config = _

    private def parse(): Config = {
        val example = getClass.getSimpleName.stripSuffix("$")
        val parser = new scopt.OptionParser[Config](example) {
            import CustomReads._

            opt[Resources]('r', "resources")
                .action { (resources, config) => config.copy(resources=resources) }
                .text("configure access to external resources")

            opt[Unit]('d', "dev")
                .action { (_, config) =>
                    IdGenerator.setImplementation(CounterGenerator, silent=true)
                    config.copy(resources=Resources.AbsoluteDev)
                }
                .text("enable development mode")

            opt[Unit]('q', "quiet")
                .action { (_, config) => config.copy(quiet=true) }
                .text("don't print messages to the terminal")

            help("help") text("prints this usage text")
        }

        parser.parse(args, Config()) getOrElse { sys.exit(1) }
    }

    override def delayedInit(body: => Unit) {
        val fn = () => _config = parse()
        super.delayedInit({ fn(); body })
    }

    def info(text: => String) {
        if (!config.quiet) println(text)
    }
}



import breeze.linalg.{DenseMatrix,linspace}

object Anscombe extends Example {
    val quartets = List('xi, 'yi, 'xii, 'yii, 'xiii, 'yiii, 'xiv, 'yiv)

    val raw_columns = DenseMatrix(
        (10.0,   8.04,   10.0,   9.14,   10.0,   7.46,   8.0,    6.58),
        (8.0,    6.95,   8.0,    8.14,   8.0,    6.77,   8.0,    5.76),
        (13.0,   7.58,   13.0,   8.74,   13.0,   12.74,  8.0,    7.71),
        (9.0,    8.81,   9.0,    8.77,   9.0,    7.11,   8.0,    8.84),
        (11.0,   8.33,   11.0,   9.26,   11.0,   7.81,   8.0,    8.47),
        (14.0,   9.96,   14.0,   8.10,   14.0,   8.84,   8.0,    7.04),
        (6.0,    7.24,   6.0,    6.13,   6.0,    6.08,   8.0,    5.25),
        (4.0,    4.26,   4.0,    3.10,   4.0,    5.39,   19.0,   12.5),
        (12.0,   10.84,  12.0,   9.13,   12.0,   8.15,   8.0,    5.56),
        (7.0,    4.82,   7.0,    7.26,   7.0,    6.42,   8.0,    7.91),
        (5.0,    5.68,   5.0,    4.74,   5.0,    5.73,   8.0,    6.89))

    val data = quartets.zip(0 until raw_columns.cols).map {
        case (quartet, i) => quartet -> raw_columns(::, i)
    }

    val circles_source = new ColumnDataSource()

    data.foreach { case (name, array) =>
        circles_source.addColumn(name, array)
    }

    object lines_source extends ColumnDataSource {
        val x = column(linspace(-0.5, 20.5, 10))
        val y = column(x.value*0.5 + 3.0)
    }

    import lines_source.{x,y}

    val xdr = new Range1d().start(-0.5).end(20.5)
    val ydr = new Range1d().start(-0.5).end(20.5)

    def make_plot(title: String, xname: Symbol, yname: Symbol) = {
        val plot = new Plot()
            .x_range(xdr)
            .y_range(ydr)
            .title(title)
            .width(400)
            .height(400)
            .border_fill(Color.White)
            .background_fill("#e9e0db")
        val xaxis = new LinearAxis().plot(plot).axis_line_color()
        val yaxis = new LinearAxis().plot(plot).axis_line_color()
        plot.below <<= (xaxis :: _)
        plot.left <<= (yaxis :: _)
        val xgrid = new Grid().plot(plot).axis(xaxis).dimension(0)
        val ygrid = new Grid().plot(plot).axis(yaxis).dimension(1)
        val line_renderer = new GlyphRenderer()
            .data_source(lines_source)
            .glyph(new Line().x(x).y(y).line_color("#666699").line_width(2))
        val circle_renderer = new GlyphRenderer()
            .data_source(circles_source)
            .glyph(new Circle().x(xname).y(yname).size(12).fill_color("#cc6633").line_color("#cc6633").fill_alpha(50%%))
        plot.renderers := List(xaxis, yaxis, xgrid, ygrid, line_renderer, circle_renderer)
        plot
    }

    val I   = make_plot("I",   'xi,   'yi)
    val II  = make_plot("II",  'xii,  'yii)
    val III = make_plot("III", 'xiii, 'yiii)
    val IV  = make_plot("IV",  'xiv,  'yiv)

    val children = List(List(I, II), List(III, IV))
    val grid = new GridPlot().children(children).width(800)

    val document = new Document(grid)
    val html = document.save("anscombe.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import org.joda.time.{LocalDate=>Date}

object Calendars extends Example {
    implicit class DateOps(date: Date) {
        def weekday: Int = date.getDayOfWeek - 1
        def month: Int = date.getMonthOfYear
        def day: Int = date.getDayOfMonth
    }

    class Calendar(firstweekday: Int) {
        def itermonthdates(year: Int, month: Int): List[Date] = {
            val date = new Date(year, month, 1)
            val days = (date.weekday - firstweekday) % 7

            def iterdates(date: Date): List[Date] = {
                date :: {
                    val next = date.plusDays(1)
                    if (next.month != month && next.weekday == firstweekday) Nil else iterdates(next)
                }
            }

            iterdates(date.minusDays(days))
        }

        def itermonthdays(year: Int, month: Int): List[Int] = {
            itermonthdates(year, month).map { date =>
                if (date.month != month) 0 else date.day
            }
        }
    }

    val symbols = new java.text.DateFormatSymbols(java.util.Locale.US)
    val day_abbrs = List("Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun")
    val month_names = symbols.getMonths().filter(_.nonEmpty)

    def make_calendar(year: Int, month: Int, nameOfFirstweekday: String = "Mon"): Plot = {
        val firstweekday = day_abbrs.indexOf(nameOfFirstweekday)
        val calendar = new Calendar(firstweekday=firstweekday)

        val month_days  = calendar.itermonthdays(year, month).map(day => if (day == 0) None else Some(day.toString))
        val month_weeks = month_days.length/7

        val workday = Color.Linen
        val weekend = Color.LightSteelBlue

        def weekday(date: Date): Int = {
            (date.weekday - firstweekday) % 7
        }

        def pick_weekdays[T](days: List[T]): List[T] = {
            firstweekday until (firstweekday+7) map { i => days(i % 7) } toList
        }

        val day_names = pick_weekdays(day_abbrs)
        val week_days = pick_weekdays(List(workday)*5 ++ List(weekend)*2)

        val source = new ColumnDataSource()
            .addColumn('days,            day_names*month_weeks)
            .addColumn('weeks,           (0 until month_weeks).flatMap(week => List(week.toString)*7))
            .addColumn('month_days,      month_days)
            .addColumn('day_backgrounds, (List(week_days)*month_weeks).flatten)

        import sampledata.{us_holidays,Holiday}

        val holidays = us_holidays.collect {
            case Holiday(date, summary) if date.getYear == year && date.month == month && summary.contains("(US-OPM)") =>
                Holiday(date, summary.replace("(US-OPM)", "").trim())
        }

        val holidays_source = new ColumnDataSource()
            .addColumn('holidays_days,  holidays.map(holiday => day_names(weekday(holiday.date))))
            .addColumn('holidays_weeks, holidays.map(holiday => ((weekday(holiday.date.withDayOfMonth(1)) + holiday.date.day) / 7).toString))
            .addColumn('month_holidays, holidays.map(holiday => holiday.summary))

        val xdr = new FactorRange().factors(day_names)
        val ydr = new FactorRange().factors((0 until month_weeks).map( _.toString).reverse.toList)

        val plot = new Plot()
            .title(month_names(month-1))
            .title_text_color(Color.DarkOliveGreen)
            .x_range(xdr)
            .y_range(ydr)
            .width(300)
            .height(300)
            .outline_line_color()

        val days_glyph = new Rect().x('days).y('weeks).width(0.9).height(0.9).fill_color('day_backgrounds).line_color(Color.Silver)
        val days_renderer = new GlyphRenderer().data_source(source).glyph(days_glyph)

        val holidays_glyph = new Rect().x('holidays_days).y('holidays_weeks).width(0.9).height(0.9).fill_color(Color.Pink).line_color(Color.IndianRed)
        val holidays_renderer = new GlyphRenderer().data_source(holidays_source).glyph(holidays_glyph)

        val text_glyph = new Text().x('days).y('weeks).text('month_days).text_align(TextAlign.Center).text_baseline(TextBaseline.Middle)
        val text_renderer = new GlyphRenderer().data_source(source).glyph(text_glyph)

        val xaxis = new CategoricalAxis()
            .plot(plot)
            .major_label_text_font_size(8 pt)
            .major_label_standoff(0)
            .major_tick_line_color()
            .axis_line_color()
        plot.above <<= (xaxis :: _)

        val hover_tool = new HoverTool().plot(plot).renderers(holidays_renderer :: Nil).tooltips(Tooltip("Holiday" -> "@month_holidays"))
        plot.tools := hover_tool :: Nil

        plot.renderers := xaxis :: days_renderer :: holidays_renderer :: text_renderer :: Nil

        return plot
    }

    val months = (0 until 4).map(i => (0 until 3).map(j => make_calendar(2014, 3*i + j + 1)).toList).toList
    val grid = new GridPlot().title("Calendar 2014").toolbar_location().children(months)

    val document = new Document(grid)
    val html = document.save("calendars.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import sampledata.USState.{AK,HI}

object Choropleth extends Example {
    val excluded_states: Set[sampledata.USState] = Set(AK, HI)

    val us_states = sampledata.us_states -- excluded_states

    val us_counties = sampledata.us_counties.filterNot { case (_, county) =>
        excluded_states contains county.state
    }

    val unemployment = sampledata.unemployment

    val colors: List[Color] = List("#F1EEF6", "#D4B9DA", "#C994C7", "#DF65B0", "#DD1C77", "#980043")

    object state_source extends ColumnDataSource {
        val state_xs = column(us_states.values.map(_.lons))
        val state_ys = column(us_states.values.map(_.lats))
    }

    object county_source extends ColumnDataSource {
        val county_xs = column(us_counties.values.map(_.lons))
        val county_ys = column(us_counties.values.map(_.lats))

        val county_colors = column {
            us_counties
                .keys
                .toList
                .map(unemployment.get)
                .map {
                    case Some(rate) => colors(math.min(rate/2 toInt, 5))
                    case None => Color.Black
                }
        }
    }

    import state_source.{state_xs,state_ys}
    import county_source.{county_xs,county_ys,county_colors}

    val xdr = new DataRange1d().sources(state_xs :: Nil)
    val ydr = new DataRange1d().sources(state_ys :: Nil)

    val county_patches = new Patches()
        .xs(county_xs)
        .ys(county_ys)
        .fill_color(county_colors)
        .fill_alpha(0.7)
        .line_color(Color.White)
        .line_width(0.5)

    val state_patches = new Patches()
        .xs(state_xs)
        .ys(state_ys)
        .fill_alpha(0.0)
        .line_color("#884444")
        .line_width(2)

    val county_renderer = new GlyphRenderer()
        .data_source(county_source)
        .glyph(county_patches)

    val state_renderer = new GlyphRenderer()
        .data_source(state_source)
        .glyph(state_patches)

    val plot = new Plot()
        .x_range(xdr)
        .y_range(ydr)
        .border_fill(Color.White)
        .title("2009 Unemployment Data")
        .width(1300)
        .height(800)

    val resizetool = new ResizeTool().plot(plot)

    plot.renderers := List(county_renderer, state_renderer)
    plot.tools := List(resizetool)

    val document = new Document(plot)
    val html = document.save("choropleth.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}


object ColorSpec extends Example {
    val colors: List[Color] = List(RGB(0, 100, 120), Color.Green, Color.Blue, "#2c7fb8", RGBA(120, 230, 150, 0.5))

    object source extends ColumnDataSource {
        val x     = column(Array[Double](1, 2, 3, 4, 5))
        val y     = column(Array[Double](5, 4, 3, 2, 1))
        val color = column(colors)
    }

    import source.{x,y,color}

    val xdr = new DataRange1d().sources(x :: Nil)
    val ydr = new DataRange1d().sources(y :: Nil)

    val circle = new Circle().x(x).y(y).size(15).fill_color(color).line_color(Color.Black)

    val renderer = new GlyphRenderer()
        .data_source(source)
        .glyph(circle)

    val plot = new Plot().x_range(xdr).y_range(ydr)

    val xaxis = new DatetimeAxis().plot(plot)
    val yaxis = new LinearAxis().plot(plot)
    plot.below <<= (xaxis :: _)
    plot.left <<= (yaxis :: _)

    val pantool = new PanTool().plot(plot)
    val wheelzoomtool = new WheelZoomTool().plot(plot)

    plot.renderers := List(xaxis, yaxis, renderer)
    plot.tools := List(pantool, wheelzoomtool)

    val document = new Document(plot)
    val html = document.save("colorspec.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import math.{Pi=>pi}

object Colors extends Example {
    val css3_colors = List[(String, Color, String)](
        ("Pink",                 Color.Pink,                 /* #FFC0CB */ "Pink"),
        ("LightPink",            Color.LightPink,            /* #FFB6C1 */ "Pink"),
        ("HotPink",              Color.HotPink,              /* #FF69B4 */ "Pink"),
        ("DeepPink",             Color.DeepPink,             /* #FF1493 */ "Pink"),
        ("PaleVioletRed",        Color.PaleVioletRed,        /* #DB7093 */ "Pink"),
        ("MediumVioletRed",      Color.MediumVioletRed,      /* #C71585 */ "Pink"),
        ("LightSalmon",          Color.LightSalmon,          /* #FFA07A */ "Red"),
        ("Salmon",               Color.Salmon,               /* #FA8072 */ "Red"),
        ("DarkSalmon",           Color.DarkSalmon,           /* #E9967A */ "Red"),
        ("LightCoral",           Color.LightCoral,           /* #F08080 */ "Red"),
        ("IndianRed",            Color.IndianRed,            /* #CD5C5C */ "Red"),
        ("Crimson",              Color.Crimson,              /* #DC143C */ "Red"),
        ("FireBrick",            Color.FireBrick,            /* #B22222 */ "Red"),
        ("DarkRed",              Color.DarkRed,              /* #8B0000 */ "Red"),
        ("Red",                  Color.Red,                  /* #FF0000 */ "Red"),
        ("OrangeRed",            Color.OrangeRed,            /* #FF4500 */ "Orange"),
        ("Tomato",               Color.Tomato,               /* #FF6347 */ "Orange"),
        ("Coral",                Color.Coral,                /* #FF7F50 */ "Orange"),
        ("DarkOrange",           Color.DarkOrange,           /* #FF8C00 */ "Orange"),
        ("Orange",               Color.Orange,               /* #FFA500 */ "Orange"),
        ("Yellow",               Color.Yellow,               /* #FFFF00 */ "Yellow"),
        ("LightYellow",          Color.LightYellow,          /* #FFFFE0 */ "Yellow"),
        ("LemonChiffon",         Color.LemonChiffon,         /* #FFFACD */ "Yellow"),
        ("LightGoldenRodYellow", Color.LightGoldenRodYellow, /* #FAFAD2 */ "Yellow"),
        ("PapayaWhip",           Color.PapayaWhip,           /* #FFEFD5 */ "Yellow"),
        ("Moccasin",             Color.Moccasin,             /* #FFE4B5 */ "Yellow"),
        ("PeachPuff",            Color.PeachPuff,            /* #FFDAB9 */ "Yellow"),
        ("PaleGoldenRod",        Color.PaleGoldenRod,        /* #EEE8AA */ "Yellow"),
        ("Khaki",                Color.Khaki,                /* #F0E68C */ "Yellow"),
        ("DarkKhaki",            Color.DarkKhaki,            /* #BDB76B */ "Yellow"),
        ("Gold",                 Color.Gold,                 /* #FFD700 */ "Yellow"),
        ("Cornsilk",             Color.Cornsilk,             /* #FFF8DC */ "Brown"),
        ("BlanchedAlmond",       Color.BlanchedAlmond,       /* #FFEBCD */ "Brown"),
        ("Bisque",               Color.Bisque,               /* #FFE4C4 */ "Brown"),
        ("NavajoWhite",          Color.NavajoWhite,          /* #FFDEAD */ "Brown"),
        ("Wheat",                Color.Wheat,                /* #F5DEB3 */ "Brown"),
        ("BurlyWood",            Color.BurlyWood,            /* #DEB887 */ "Brown"),
        ("Tan",                  Color.Tan,                  /* #D2B48C */ "Brown"),
        ("RosyBrown",            Color.RosyBrown,            /* #BC8F8F */ "Brown"),
        ("SandyBrown",           Color.SandyBrown,           /* #F4A460 */ "Brown"),
        ("GoldenRod",            Color.GoldenRod,            /* #DAA520 */ "Brown"),
        ("DarkGoldenRod",        Color.DarkGoldenRod,        /* #B8860B */ "Brown"),
        ("Peru",                 Color.Peru,                 /* #CD853F */ "Brown"),
        ("Chocolate",            Color.Chocolate,            /* #D2691E */ "Brown"),
        ("SaddleBrown",          Color.SaddleBrown,          /* #8B4513 */ "Brown"),
        ("Sienna",               Color.Sienna,               /* #A0522D */ "Brown"),
        ("Brown",                Color.Brown,                /* #A52A2A */ "Brown"),
        ("Maroon",               Color.Maroon,               /* #800000 */ "Brown"),
        ("DarkOliveGreen",       Color.DarkOliveGreen,       /* #556B2F */ "Green"),
        ("Olive",                Color.Olive,                /* #808000 */ "Green"),
        ("OliveDrab",            Color.OliveDrab,            /* #6B8E23 */ "Green"),
        ("YellowGreen",          Color.YellowGreen,          /* #9ACD32 */ "Green"),
        ("LimeGreen",            Color.LimeGreen,            /* #32CD32 */ "Green"),
        ("Lime",                 Color.Lime,                 /* #00FF00 */ "Green"),
        ("LawnGreen",            Color.LawnGreen,            /* #7CFC00 */ "Green"),
        ("Chartreuse",           Color.Chartreuse,           /* #7FFF00 */ "Green"),
        ("GreenYellow",          Color.GreenYellow,          /* #ADFF2F */ "Green"),
        ("SpringGreen",          Color.SpringGreen,          /* #00FF7F */ "Green"),
        ("MediumSpringGreen",    Color.MediumSpringGreen,    /* #00FA9A */ "Green"),
        ("LightGreen",           Color.LightGreen,           /* #90EE90 */ "Green"),
        ("PaleGreen",            Color.PaleGreen,            /* #98FB98 */ "Green"),
        ("DarkSeaGreen",         Color.DarkSeaGreen,         /* #8FBC8F */ "Green"),
        ("MediumSeaGreen",       Color.MediumSeaGreen,       /* #3CB371 */ "Green"),
        ("SeaGreen",             Color.SeaGreen,             /* #2E8B57 */ "Green"),
        ("ForestGreen",          Color.ForestGreen,          /* #228B22 */ "Green"),
        ("Green",                Color.Green,                /* #008000 */ "Green"),
        ("DarkGreen",            Color.DarkGreen,            /* #006400 */ "Green"),
        ("MediumAquaMarine",     Color.MediumAquaMarine,     /* #66CDAA */ "Cyan"),
        ("Aqua",                 Color.Aqua,                 /* #00FFFF */ "Cyan"),
        ("Cyan",                 Color.Cyan,                 /* #00FFFF */ "Cyan"),
        ("LightCyan",            Color.LightCyan,            /* #E0FFFF */ "Cyan"),
        ("PaleTurquoise",        Color.PaleTurquoise,        /* #AFEEEE */ "Cyan"),
        ("AquaMarine",           Color.AquaMarine,           /* #7FFFD4 */ "Cyan"),
        ("Turquoise",            Color.Turquoise,            /* #40E0D0 */ "Cyan"),
        ("MediumTurquoise",      Color.MediumTurquoise,      /* #48D1CC */ "Cyan"),
        ("DarkTurquoise",        Color.DarkTurquoise,        /* #00CED1 */ "Cyan"),
        ("LightSeaGreen",        Color.LightSeaGreen,        /* #20B2AA */ "Cyan"),
        ("CadetBlue",            Color.CadetBlue,            /* #5F9EA0 */ "Cyan"),
        ("DarkCyan",             Color.DarkCyan,             /* #008B8B */ "Cyan"),
        ("Teal",                 Color.Teal,                 /* #008080 */ "Cyan"),
        ("LightSteelBlue",       Color.LightSteelBlue,       /* #B0C4DE */ "Blue"),
        ("PowderBlue",           Color.PowderBlue,           /* #B0E0E6 */ "Blue"),
        ("LightBlue",            Color.LightBlue,            /* #ADD8E6 */ "Blue"),
        ("SkyBlue",              Color.SkyBlue,              /* #87CEEB */ "Blue"),
        ("LightSkyBlue",         Color.LightSkyBlue,         /* #87CEFA */ "Blue"),
        ("DeepSkyBlue",          Color.DeepSkyBlue,          /* #00BFFF */ "Blue"),
        ("DodgerBlue",           Color.DodgerBlue,           /* #1E90FF */ "Blue"),
        ("CornFlowerBlue",       Color.CornFlowerBlue,       /* #6495ED */ "Blue"),
        ("SteelBlue",            Color.SteelBlue,            /* #4682B4 */ "Blue"),
        ("RoyalBlue",            Color.RoyalBlue,            /* #4169E1 */ "Blue"),
        ("Blue",                 Color.Blue,                 /* #0000FF */ "Blue"),
        ("MediumBlue",           Color.MediumBlue,           /* #0000CD */ "Blue"),
        ("DarkBlue",             Color.DarkBlue,             /* #00008B */ "Blue"),
        ("Navy",                 Color.Navy,                 /* #000080 */ "Blue"),
        ("MidnightBlue",         Color.MidnightBlue,         /* #191970 */ "Blue"),
        ("Lavender",             Color.Lavender,             /* #E6E6FA */ "Purple"),
        ("Thistle",              Color.Thistle,              /* #D8BFD8 */ "Purple"),
        ("Plum",                 Color.Plum,                 /* #DDA0DD */ "Purple"),
        ("Violet",               Color.Violet,               /* #EE82EE */ "Purple"),
        ("Orchid",               Color.Orchid,               /* #DA70D6 */ "Purple"),
        ("Fuchsia",              Color.Fuchsia,              /* #FF00FF */ "Purple"),
        ("Magenta",              Color.Magenta,              /* #FF00FF */ "Purple"),
        ("MediumOrchid",         Color.MediumOrchid,         /* #BA55D3 */ "Purple"),
        ("MediumPurple",         Color.MediumPurple,         /* #9370DB */ "Purple"),
        ("BlueViolet",           Color.BlueViolet,           /* #8A2BE2 */ "Purple"),
        ("DarkViolet",           Color.DarkViolet,           /* #9400D3 */ "Purple"),
        ("DarkOrchid",           Color.DarkOrchid,           /* #9932CC */ "Purple"),
        ("DarkMagenta",          Color.DarkMagenta,          /* #8B008B */ "Purple"),
        ("Purple",               Color.Purple,               /* #800080 */ "Purple"),
        ("Indigo",               Color.Indigo,               /* #4B0082 */ "Purple"),
        ("DarkSlateBlue",        Color.DarkSlateBlue,        /* #483D8B */ "Purple"),
        ("SlateBlue",            Color.SlateBlue,            /* #6A5ACD */ "Purple"),
        ("MediumSlateBlue",      Color.MediumSlateBlue,      /* #7B68EE */ "Purple"),
        ("White",                Color.White,                /* #FFFFFF */ "White"),
        ("Snow",                 Color.Snow,                 /* #FFFAFA */ "White"),
        ("HoneyDew",             Color.HoneyDew,             /* #F0FFF0 */ "White"),
        ("MintCream",            Color.MintCream,            /* #F5FFFA */ "White"),
        ("Azure",                Color.Azure,                /* #F0FFFF */ "White"),
        ("AliceBlue",            Color.AliceBlue,            /* #F0F8FF */ "White"),
        ("GhostWhite",           Color.GhostWhite,           /* #F8F8FF */ "White"),
        ("WhiteSmoke",           Color.WhiteSmoke,           /* #F5F5F5 */ "White"),
        ("Seashell",             Color.Seashell,             /* #FFF5EE */ "White"),
        ("Beige",                Color.Beige,                /* #F5F5DC */ "White"),
        ("OldLace",              Color.OldLace,              /* #FDF5E6 */ "White"),
        ("FloralWhite",          Color.FloralWhite,          /* #FFFAF0 */ "White"),
        ("Ivory",                Color.Ivory,                /* #FFFFF0 */ "White"),
        ("AntiqueWhite",         Color.AntiqueWhite,         /* #FAEBD7 */ "White"),
        ("Linen",                Color.Linen,                /* #FAF0E6 */ "White"),
        ("LavenderBlush",        Color.LavenderBlush,        /* #FFF0F5 */ "White"),
        ("MistyRose",            Color.MistyRose,            /* #FFE4E1 */ "White"),
        ("Gainsboro",            Color.Gainsboro,            /* #DCDCDC */ "Gray/Black"),
        ("LightGray",            Color.LightGray,            /* #D3D3D3 */ "Gray/Black"),
        ("Silver",               Color.Silver,               /* #C0C0C0 */ "Gray/Black"),
        ("DarkGray",             Color.DarkGray,             /* #A9A9A9 */ "Gray/Black"),
        ("Gray",                 Color.Gray,                 /* #808080 */ "Gray/Black"),
        ("DimGray",              Color.DimGray,              /* #696969 */ "Gray/Black"),
        ("LightSlateGray",       Color.LightSlateGray,       /* #778899 */ "Gray/Black"),
        ("SlateGray",            Color.SlateGray,            /* #708090 */ "Gray/Black"),
        ("DarkSlateGray",        Color.DarkSlateGray,        /* #2F4F4F */ "Gray/Black"),
        ("Black",                Color.Black,                /* #000000 */ "Gray/Black"))

    object source extends ColumnDataSource {
        val names  = column(css3_colors.map(_._1))
        val colors = column(css3_colors.map(_._2))
        val groups = column(css3_colors.map(_._3))
    }

    import source.{names,colors,groups}

    val xdr = new FactorRange().factors(groups.value.distinct)
    val ydr = new FactorRange().factors(names.value.reverse)

    val plot = new Plot().title("CSS3 Color Names").x_range(xdr).y_range(ydr).width(600).height(2000)

    // TODO: categorical dimensions; using Column would cause type error
    val rect_glyph = new Rect().x('groups).y('names).width(1).height(1).fill_color(colors).line_color()
    val rect = new GlyphRenderer().data_source(source).glyph(rect_glyph)

    val x1axis = new CategoricalAxis().plot(plot).major_label_orientation(pi/4)
    plot.above := x1axis :: Nil
    val x2axis = new CategoricalAxis().plot(plot).major_label_orientation(pi/4)
    plot.below := x2axis :: Nil
    val yaxis = new CategoricalAxis().plot(plot)
    plot.left  := yaxis :: Nil

    plot.renderers := x1axis :: x2axis :: yaxis :: rect :: Nil

    val url = "http://www.colors.commutercreative.com/@names/"
    val tooltips = Tooltip(s"""Click the color to go to:<br /><a href="$url">$url</a>""")

    val tap = new TapTool().plot(plot).renderers(rect :: Nil).action(new OpenURL().url(url))
    val hover = new HoverTool().plot(plot).renderers(rect :: Nil).tooltips(tooltips)
    plot.tools := List(tap, hover)

    val document = new Document(plot)
    val html = document.save("colors.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}


import widgets.{
    VBox,
    DataTable,TableColumn,
    NumberFormatter,StringFormatter,
    IntEditor,NumberEditor,StringEditor,SelectEditor}

object DataTables extends Example {
    val mpg = sampledata.autompg

    object source extends ColumnDataSource {
        val index = column(mpg.index)
        val manufacturer = column(mpg.manufacturer)
        val model = column(mpg.model)
        val displ = column(mpg.displ)
        val year = column(mpg.year)
        val cyl = column(mpg.cyl)
        val trans = column(mpg.trans)
        val drv = column(mpg.drv)
        val cls = column(mpg.cls)
        val cty = column(mpg.cty)
        val hwy = column(mpg.hwy)
    }

    import source.{index,manufacturer,model,displ,year,cyl,trans,drv,cls,cty,hwy}

    val plot = {
        val xdr = new DataRange1d().sources(index :: Nil)
        val ydr = new DataRange1d().sources(List(cty, hwy))
        val plot = new Plot().title().x_range(xdr).y_range(ydr).width(1000).height(300)
        val xaxis = new LinearAxis().plot(plot)
        plot.below <<= (xaxis :: _)
        val yaxis = new LinearAxis().plot(plot)
        val ygrid = new Grid().plot(plot).dimension(1).ticker(yaxis.ticker.value)
        plot.left <<= (yaxis :: _)
        val cty_glyph = new Circle().x('index).y(cty).fill_color("#396285").size(8).fill_alpha(0.5).line_alpha(0.5)
        val hwy_glyph = new Circle().x('index).y(hwy).fill_color("#CE603D").size(8).fill_alpha(0.5).line_alpha(0.5)
        val cty_renderer = new GlyphRenderer().data_source(source).glyph(cty_glyph)
        val hwy_renderer = new GlyphRenderer().data_source(source).glyph(hwy_glyph)
        plot.renderers := List(cty_renderer, hwy_renderer, xaxis, yaxis, ygrid)
        val tooltips = List(
            "Manufacturer" -> "@manufacturer",
            "Model"        -> "@model",
            "Displacement" -> "@displ",
            "Year"         -> "@year",
            "Cylinders"    -> "@cyl",
            "Transmission" -> "@trans",
            "Drive"        -> "@drv",
            "Class"        -> "@cls")
        val cty_hover_tool = new HoverTool().plot(plot).renderers(cty_renderer :: Nil).tooltips(Tooltip(tooltips :+ ("City MPG"    -> "@cty")))
        val hwy_hover_tool = new HoverTool().plot(plot).renderers(hwy_renderer :: Nil).tooltips(Tooltip(tooltips :+ ("Highway MPG" -> "@hwy")))
        val select_tool = new BoxSelectTool().plot(plot).renderers(cty_renderer :: hwy_renderer :: Nil).dimensions(Dimension.Width :: Nil)
        plot.tools := List(cty_hover_tool, hwy_hover_tool, select_tool)
        plot
    }

    val data_table = {
        val manufacturers = mpg.manufacturer.distinct.sorted
        val models        = mpg.model.distinct.sorted
        val transmissions = mpg.trans.distinct.sorted
        val drives        = mpg.drv.distinct.sorted
        val classes       = mpg.cls.distinct.sorted

        val columns = List(
            new TableColumn().field('manufacturer) .title("Manufacturer") .editor(new SelectEditor().options(manufacturers)) .formatter(new StringFormatter().font_style(FontStyle.Bold)),
            new TableColumn().field('model)        .title("Model")        .editor(new StringEditor().completions(models)),
            new TableColumn().field('displ)        .title("Displacement") .editor(new NumberEditor().step(0.1))              .formatter(new NumberFormatter().format("0.0")),
            new TableColumn().field('year)         .title("Year")         .editor(new IntEditor()),
            new TableColumn().field('cyl)          .title("Cylinders")    .editor(new IntEditor()),
            new TableColumn().field('trans)        .title("Transmission") .editor(new SelectEditor().options(transmissions)),
            new TableColumn().field('drv)          .title("Drive")        .editor(new SelectEditor().options(drives)),
            new TableColumn().field('cls)          .title("Class")        .editor(new SelectEditor().options(classes)),
            new TableColumn().field('cty)          .title("City MPG")     .editor(new IntEditor()),
            new TableColumn().field('hwy)          .title("Highway MPG")  .editor(new IntEditor())
        )
        new DataTable().source(source).columns(columns).editable(true)
    }

    val layout = new VBox().children(plot :: data_table :: Nil)

    val document = new Document(layout)
    val html = document.save("data_tables.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import math.{Pi=>pi,sin}

object DateAxis extends Example {
    val now = System.currentTimeMillis.toDouble/1000
    val x   = -2*pi to 2*pi by 0.1

    object source extends ColumnDataSource {
        val times = column(x.indices.map(3600000.0*_ + now))
        val y     = column(x.map(sin))
    }

    import source.{times,y}

    val xdr = new DataRange1d().sources(times :: Nil)
    val ydr = new DataRange1d().sources(y :: Nil)

    val circle = new Circle().x(times).y(y).fill_color(Color.Red).size(5).line_color(Color.Black)

    val renderer = new GlyphRenderer()
        .data_source(source)
        .glyph(circle)

    val plot = new Plot().x_range(xdr).y_range(ydr)

    val xaxis = new DatetimeAxis().plot(plot)
    val yaxis = new LinearAxis().plot(plot)
    plot.below <<= (xaxis :: _)
    plot.left <<= (yaxis :: _)

    val pantool = new PanTool().plot(plot)
    val wheelzoomtool = new WheelZoomTool().plot(plot)

    plot.renderers := List(xaxis, yaxis, renderer)
    plot.tools := List(pantool, wheelzoomtool)

    val document = new Document(plot)
    val html = document.save("dateaxis.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import org.joda.time.{LocalTime=>Time,LocalDate=>Date}

object Daylight extends Example {
    val daylight = sampledata.daylight.Warsaw2013

    val source = new ColumnDataSource()
        .addColumn('dates, daylight.date)
        .addColumn('sunrises, daylight.sunrise)
        .addColumn('sunsets, daylight.sunset)

    val patch1_source = new ColumnDataSource()
        .addColumn('dates, daylight.date ++ daylight.date.reverse)
        .addColumn('times, daylight.sunrise ++ daylight.sunset.reverse)

    val summer = daylight.summerOnly

    val patch2_source = new ColumnDataSource()
        .addColumn('dates, summer.date ++ summer.date.reverse)
        .addColumn('times, summer.sunrise ++ summer.sunset.reverse)

    val summerStartIndex = daylight.summer.indexOf(true)
    val summerEndIndex   = daylight.summer.indexOf(false, summerStartIndex)

    val calendarStart = daylight.date.head
    val summerStart   = daylight.date(summerStartIndex)
    val summerEnd     = daylight.date(summerEndIndex)
    val calendarEnd   = daylight.date.last

    def middle(start: Date, end: Date) =
        new Date((start.toDateTimeAtStartOfDay.getMillis + end.toDateTimeAtStartOfDay.getMillis) / 2)

    val springMiddle = middle(summerStart, calendarStart)
    val summerMiddle = middle(summerEnd,   summerStart)
    val autumnMiddle = middle(calendarEnd, summerEnd)

    val _11_30 = new Time(11, 30)

    val text_source = new ColumnDataSource()
        .addColumn('dates, List(springMiddle, summerMiddle, autumnMiddle))
        .addColumn('times, List(_11_30, _11_30, _11_30))
        .addColumn('texts, List("CST (UTC+1)", "CEST (UTC+2)", "CST (UTC+1)"))

    val xdr = new DataRange1d().sources(List(source.columns('dates)))
    val ydr = new DataRange1d().sources(List(source.columns('sunrises, 'sunsets)))

    val title = "Daylight Hours - Warsaw, Poland"
    val sources = List(source, patch1_source, patch2_source, text_source)
    val plot = new Plot().title(title).x_range(xdr).y_range(ydr).width(800).height(400)

    val patch1 = new Patch().x('dates).y('times).fill_color(Color.SkyBlue).fill_alpha(0.8)
    val patch1_glyph = new GlyphRenderer().data_source(patch1_source).glyph(patch1)

    val patch2 = new Patch().x('dates).y('times).fill_color(Color.Orange).fill_alpha(0.8)
    val patch2_glyph = new GlyphRenderer().data_source(patch2_source).glyph(patch2)

    val line1 = new Line().x('dates).y('sunrises).line_color(Color.Yellow).line_width(2)
    val line1_glyph = new GlyphRenderer().data_source(source).glyph(line1)

    val line2 = new Line().x('dates).y('sunsets).line_color(Color.Red).line_width(2)
    val line2_glyph = new GlyphRenderer().data_source(source).glyph(line2)

    val text = new Text().x('dates).y('times).text('texts).angle(0).text_align(TextAlign.Center)
    val text_glyph = new GlyphRenderer().data_source(text_source).glyph(text)

    val glyphs = List(patch1_glyph, patch2_glyph, line1_glyph, line2_glyph, text_glyph)
    plot.renderers <<= (glyphs ++ _)

    val xformatter = new DatetimeTickFormatter().formats(Map(DatetimeUnits.Months -> List("%b %Y")))
    val xaxis = new DatetimeAxis().plot(plot).formatter(xformatter)
    val yaxis = new DatetimeAxis().plot(plot)
    plot.below <<= (xaxis :: _)
    plot.left <<= (yaxis :: _)
    val xgrid = new Grid().plot(plot).dimension(0).axis(xaxis)
    val ygrid = new Grid().plot(plot).dimension(1).axis(yaxis)

    plot.renderers <<= (xaxis :: yaxis :: xgrid :: ygrid :: _)

    val legends = List("sunrise" -> List(line1_glyph),
                       "sunset"  -> List(line2_glyph))
    val legend = new Legend().plot(plot).legends(legends)
    plot.renderers <<= (legend :: _)

    val document = new Document(plot)
    val html = document.save("daylight.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import math.{Pi=>pi,sin,cos}
import sampledata.webbrowsers.{webbrowsers_nov_2013,WebBrowserIcons}

object Donut extends Example {
    val xdr = new Range1d().start(-2).end(2)
    val ydr = new Range1d().start(-2).end(2)

    val title = "Web browser market share (November 2013)"
    val plot = new Plot().title(title).x_range(xdr).y_range(ydr).plot_width(800).plot_height(800)

    val colors = Map(
        "Chrome"  -> Color.SeaGreen,
        "Firefox" -> Color.Tomato,
        "Safari"  -> Color.Orchid,
        "Opera"   -> Color.FireBrick,
        "IE"      -> Color.SkyBlue,
        "Other"   -> Color.LightGray)

    val icons = Map(
        "Chrome"  -> WebBrowserIcons.Chrome,
        "Firefox" -> WebBrowserIcons.Firefox,
        "Safari"  -> WebBrowserIcons.Safari,
        "Opera"   -> WebBrowserIcons.Opera,
        "IE"      -> WebBrowserIcons.IE,
        "Other"   -> "")

    case class WebBrowserData(browser: String, version: String, share: Double)

    val df = webbrowsers_nov_2013
    val data = (df.browser, df.version, df.share).zipped.map {
        case (browser, version, share) => WebBrowserData(browser, version, share)
    }

    val aggregated = data.groupBy(_.browser).mapValues(_.map(_.share).sum)

    def agg(fn: Double => Boolean) = aggregated.filter { case (_, share) => fn(share) }
    val selected = agg(_ >= 1) + ("Other" -> agg(_ < 1).values.sum)

    val browsers = selected.keys
    val angles = selected.values.map(2*pi*_/100).scanLeft(0.0)(_ + _)

    val start_angles = angles.init.toList
    val end_angles = angles.tail.toList

    val browsers_source = new ColumnDataSource().data(Map(
        'start  -> start_angles,
        'end    -> end_angles,
        'colors -> browsers.map(colors)))

    val glyph = new Wedge().x(0).y(0).radius(1).line_color(Color.White).line_width(2).start_angle('start).end_angle('end).fill_color('colors)
    plot.addGlyph(browsers_source, glyph)

    def polar_to_cartesian(r: Double, start_angles: Seq[Double], end_angles: Seq[Double]): (Seq[Double], Seq[Double]) = {
        start_angles.zip(end_angles)
                    .map { case (start, end) => (end + start)/2 }
                    .map { angle => (r*cos(angle), r*sin(angle)) }
                    .unzip
    }

    for {
        browser     <- browsers
        start_angle <- start_angles
        end_angle   <- end_angles
    } {
        /*
        val versions = data.filter(_.browser == browser).filter(_.share >= 0.5).map(_.version)
        val angles = versions.Share.map(radians).cumsum() + start_angle
        val end = angles.tolist() + [end_angle]
        val start = [start_angle] + end[:-1]
        val base_color = colors[browser]
        val fill = [ base_color.lighten(i*0.05) for i in range(len(versions) + 1) ]
        val text = [ number if share >= 1 else "" for number, share in zip(versions.VersionNumber, versions.Share) ]
        val (x, y) = polar_to_cartesian(1.25, start, end)

        {
            val source = new ColumnDataSource().data(Map('start -> start, 'end -> end, 'fill -> fill))
            val glyph = new AnnularWedge().x(0).y(0).inner_radius(1).outer_radius(1.5).start_angle('start).end_angle('end).line_color(Color.White).line_width(2).fill_color('fill)
            plot.addGlyph(source, glyph)
        }

        val text_angle = [(start[i] + end[i])/2 for i in range(len(start))]
        val text_angle = [angle + pi if pi/2 < angle < 3*pi/2 else angle for angle in text_angle]

        {
            val source = new ColumnDataSource().data(Map('text -> text, 'x -> x, 'y -> y, 'angle -> text_angle))
            val glyph = new Text().x('x).y('y).text('text).angle('angle).text_align(TextAlign.Center).text_baseline(TextBaseline.Middle)
            plot.addGlyph(source, glyph)
        }
        */
    }

    {
        val urls = browsers.map(icons)
        val (x, y) = polar_to_cartesian(1.7, start_angles, end_angles)

        val source = new ColumnDataSource().data(Map('urls -> urls, 'x -> x, 'y -> y))
        val glyph = new ImageURL().url('urls).x('x).y('y).angle(0.0).anchor(Anchor.Center)
        plot.addGlyph(source, glyph)
    }

    {
        val text = selected.values.map(share => f"$share%.02f%%")
        val (x, y) = polar_to_cartesian(0.7, start_angles, end_angles)

        val source = new ColumnDataSource().data(Map('text -> text, 'x -> x, 'y -> y))
        val glyph = new Text().x('x).y('y).text('text).angle(0).text_align(TextAlign.Center).text_baseline(TextBaseline.Middle)
        plot.addGlyph(source, glyph)
    }

    val document = new Document(plot)
    val html = document.save("donut.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import math.{Pi=>pi,sin,cos}

object Gauges extends Example {
    val start_angle = pi + pi/4
    val end_angle = -pi/4

    val max_kmh = 250
    val max_mph = max_kmh*0.621371

    val major_step = 25
    val minor_step = 5

    val xdr = new Range1d().start(-1.25).end(1.25)
    val ydr = new Range1d().start(-1.25).end(1.25)

    val plot = new Plot().title("Speedometer").x_range(xdr).y_range(ydr).width(600).height(600)

    plot.addGlyph(new Circle().x(0).y(0).radius(1.00).fill_color(Color.White).line_color(Color.Black))
    plot.addGlyph(new Circle().x(0).y(0).radius(0.05).fill_color(Color.Gray).line_color(Color.Black))

    plot.addGlyph(new Text().x(0).y(+0.15).angle(0).text("km/h").text_color(Color.Red)
        .text_align(TextAlign.Center).text_baseline(TextBaseline.Bottom).text_font_style(FontStyle.Bold))
    plot.addGlyph(new Text().x(0).y(-0.15).angle(0).text("mph").text_color(Color.Blue)
        .text_align(TextAlign.Center).text_baseline(TextBaseline.Top).text_font_style(FontStyle.Bold))

    def speed_to_angle(speed: Double, kmh_units: Boolean): Double = {
        val max_speed = if (kmh_units) max_kmh else max_mph
        val bounded_speed = speed.max(0).min(max_speed)
        val total_angle = start_angle - end_angle
        val angle = total_angle*bounded_speed/max_speed
        start_angle - angle
    }

    def add_needle(speed: Double, kmh_units: Boolean) {
        val angle = speed_to_angle(speed, kmh_units)
        plot.addGlyph(new Ray().x(0).y(0).length(0.75, SpatialUnits.Data).angle(angle)   .line_color(Color.Black).line_width(3))
        plot.addGlyph(new Ray().x(0).y(0).length(0.10, SpatialUnits.Data).angle(angle-pi).line_color(Color.Black).line_width(3))
    }

    def polar_to_cartesian(r: Double, alpha: Double) = (r*cos(alpha), r*sin(alpha))

    def add_gauge(radius: Double, max_value: Double, length: Double, direction: Int, color: Color, major_step: Double, minor_step: Double) {
        var major_angles = List[Double]()
        var minor_angles = List[Double]()

        val total_angle = start_angle - end_angle

        val major_angle_step = major_step/max_value*total_angle
        val minor_angle_step = minor_step/max_value*total_angle

        var major_angle = 0.0

        while (major_angle <= total_angle) {
            major_angles :+= start_angle - major_angle
            major_angle += major_angle_step
        }

        var minor_angle = 0.0

        while (minor_angle <= total_angle) {
            minor_angles :+= start_angle - minor_angle
            minor_angle += minor_angle_step
        }

        var major_labels = major_angles.zipWithIndex.map { case (_, i) => (major_step*i).toInt.toString }
        var minor_labels = minor_angles.zipWithIndex.map { case (_, i) => (minor_step*i).toInt.toString }

        val n = major_step/minor_step

        minor_angles = minor_angles.zipWithIndex.collect { case (x, i) if i % n != 0 => x }
        minor_labels = minor_labels.zipWithIndex.collect { case (x, i) if i % n != 0 => x }

        plot.addGlyph(new Arc().x(0).y(0).radius(radius).start_angle(start_angle).end_angle(end_angle).direction(Direction.Clock).line_color(color).line_width(2))

        val rotation = if (direction == 1) 0 else -pi

        {
            val (x, y) = major_angles.map(polar_to_cartesian(radius, _)).unzip
            val angles = major_angles.map(_ + rotation)
            val source = new ColumnDataSource().data(Map('x -> x, 'y -> y, 'angle -> angles))
            val glyph = new Ray().x('x).y('y).length(length, SpatialUnits.Data).angle('angle).line_color(color).line_width(2)
            plot.addGlyph(source, glyph)
        }

        {
            val (x, y) = minor_angles.map(polar_to_cartesian(radius, _)).unzip
            val angles = minor_angles.map(_ + rotation)
            val source = new ColumnDataSource().data(Map('x -> x, 'y -> y, 'angle -> angles))
            val glyph = new Ray().x('x).y('y).length(length/2, SpatialUnits.Data).angle('angle).line_color(color).line_width(1)
            plot.addGlyph(source, glyph)
        }

        {
            val (x, y) = major_angles.map(polar_to_cartesian(radius+2*length*direction, _)).unzip
            val angles = major_angles.map(_ - pi/2)
            val source = new ColumnDataSource().data(Map('x -> x, 'y -> y, 'angle -> angles, 'text -> major_labels))
            val glyph = new Text().x('x).y('y).angle('angle).text('text).text_align(TextAlign.Center).text_baseline(TextBaseline.Middle)
            plot.addGlyph(source, glyph)
        }
    }

    add_gauge(0.75, max_kmh, 0.05, +1, Color.Red,  major_step, minor_step)
    add_gauge(0.70, max_mph, 0.05, -1, Color.Blue, major_step, minor_step)

    add_needle(55, kmh_units=true)

    val document = new Document(plot)
    val html = document.save("gauges.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}

import math.Pi

object Gears extends Example with Tools {
    def pitch_radius(module: Double, teeth: Int) =
        (module*teeth)/2

    def half_tooth(teeth: Int) =
        Pi/teeth

    val line_color: Color = "#606060"
    val fill_color: (Color, Color, Color) = ("#ddd0dd", "#d0d0e8", "#ddddd0")

    def sample_gear() = {
        val xdr = new Range1d().start(-30).end(30)
        val ydr = new Range1d().start(-30).end(30)

        val plot = new Plot().x_range(xdr).y_range(ydr)
            .width(800).height(800).tools(Pan|WheelZoom|Reset)

        val glyph = new Gear().x(0).y(0).module(5).teeth(8).angle(0).shaft_size(0.2).fill_color(fill_color._3).line_color(line_color)
        val renderer = new GlyphRenderer().glyph(glyph)
        plot.renderers <<= (renderer :: _)

        plot
    }

    def classical_gear(module: Double, large_teeth: Int, small_teeth: Int) = {
        val xdr = new Range1d().start(-300).end(150)
        val ydr = new Range1d().start(-100).end(100)

        val plot = new Plot().x_range(xdr).y_range(ydr)
            .width(800).height(800).tools(Pan|WheelZoom|Reset)

        def large_gear() = {
            val radius = pitch_radius(module, large_teeth)
            val angle = 0
            val glyph = new Gear().x(-radius).y(0).module(module).teeth(large_teeth).angle(angle).fill_color(fill_color._1).line_color(line_color)
            new GlyphRenderer().glyph(glyph)
        }

        def small_gear() = {
            val radius = pitch_radius(module, small_teeth)
            val angle = half_tooth(small_teeth)
            val glyph = new Gear().x(radius).y(0).module(module).teeth(small_teeth).angle(angle).fill_color(fill_color._2).line_color(line_color)
            new GlyphRenderer().glyph(glyph)
        }

        plot.renderers <<= (large_gear() :: small_gear() :: _)
        plot
    }

    def epicyclic_gear(module: Double, sun_teeth: Int, planet_teeth: Int) = {
        val xdr = new Range1d().start(-150).end(150)
        val ydr = new Range1d().start(-150).end(150)

        val plot = new Plot().x_range(xdr).y_range(ydr)
            .width(800).height(800).tools(Pan|WheelZoom|Reset)

        val annulus_teeth = sun_teeth + 2*planet_teeth

        def annular_gear() = {
            val glyph = new Gear().x(0).y(0).module(module).teeth(annulus_teeth).angle(0).fill_color(fill_color._1).line_color(line_color).internal(true)
            new GlyphRenderer().glyph(glyph)
        }

        def sun_gear() = {
            val glyph = new Gear().x(0).y(0).module(module).teeth(sun_teeth).angle(0).fill_color(fill_color._3).line_color(line_color)
            new GlyphRenderer().glyph(glyph)
        }

        val sun_radius = pitch_radius(module, sun_teeth)
        val planet_radius = pitch_radius(module, planet_teeth)

        val radius = sun_radius + planet_radius
        val angle = half_tooth(planet_teeth)

        val planets = for ((i, j) <- List((+1, 0), (0, +1), (-1, 0), (0, -1))) yield {
            val glyph = new Gear().x(radius*i).y(radius*j).module(module).teeth(planet_teeth).angle(angle).fill_color(fill_color._2).line_color(line_color);
            new GlyphRenderer().glyph(glyph)
        }

        plot.renderers <<= (annular_gear() :: sun_gear() :: planets ++ _)
        plot
    }

    val sample    = sample_gear()
    val classical = classical_gear(5, 52, 24)
    val epicyclic = epicyclic_gear(5, 24, 12)

    val document = new Document(sample, classical, epicyclic)
    val html = document.save("gears.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}





import math.{Pi=>pi,sin}

object Glyph1 extends Example {
    object source extends ColumnDataSource {
        val x = column(-2*pi to 2*pi by 0.1)
        val y = column(x.value.map(sin))
    }

    import source.{x,y}

    val xdr = new DataRange1d().sources(x :: Nil)
    val ydr = new DataRange1d().sources(y :: Nil)

    val circle = new Circle().x(x).y(y).fill_color(Color.Red).size(5).line_color(Color.Black)
    val renderer = new GlyphRenderer().data_source(source).glyph(circle)

    val plot = new Plot().x_range(xdr).y_range(ydr)

    val xaxis = new LinearAxis().plot(plot)
    val yaxis = new LinearAxis().plot(plot)
    plot.below <<= (xaxis :: _)
    plot.left <<= (yaxis :: _)

    val pantool = new PanTool().plot(plot)
    val wheelzoomtool = new WheelZoomTool().plot(plot)

    plot.renderers := List(xaxis, yaxis, renderer)
    plot.tools := List(pantool, wheelzoomtool)

    val document = new Document(plot)
    val html = document.save("glyph1.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import breeze.linalg.DenseVector
import breeze.numerics.{sin,cos}
import math.{Pi=>pi}

object Glyph2 extends Example {
    object source extends ColumnDataSource {
        val x = column(DenseVector(-2*pi to 2*pi by 0.1 toArray))
        val y = column(sin(x.value))
        val r = column((cos(x.value) + 1.0)*6.0 + 6.0)
    }

    import source.{x,y,r}

    val xdr = new DataRange1d().sources(x :: Nil)
    val ydr = new DataRange1d().sources(y :: Nil)

    val circle = new Circle()
        .x(x)
        .y(y)
        .radius(r, SpatialUnits.Screen)
        .fill_color(Color.Red)
        .line_color(Color.Black)

    val renderer = new GlyphRenderer()
        .data_source(source)
        .glyph(circle)

    val plot = new Plot().x_range(xdr).y_range(ydr).title("glyph2")

    val pantool = new PanTool().plot(plot)
    val wheelzoomtool = new WheelZoomTool().plot(plot)

    val xaxis = new LinearAxis().plot(plot)
    val yaxis = new LinearAxis().plot(plot)
    plot.below <<= (xaxis :: _)
    plot.left <<= (yaxis :: _)

    val xgrid = new Grid().plot(plot).axis(xaxis).dimension(0)
    val ygrid = new Grid().plot(plot).axis(yaxis).dimension(1)

    plot.renderers := List(xaxis, yaxis, xgrid, ygrid, renderer)
    plot.tools := List(pantool, wheelzoomtool)

    val document = new Document(plot)
    val html = document.save("glyph2.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import breeze.linalg.linspace
import breeze.numerics.{sin,cos,tan}
import math.{Pi=>pi}

object Grid extends Example {
    object source extends ColumnDataSource {
        val x  = column(linspace(-2*pi, 2*pi, 1000))
        val y1 = column(sin(x.value))
        val y2 = column(cos(x.value))
        val y3 = column(tan(x.value))
        val y4 = column(sin(x.value) :* cos(x.value))
    }

    def make_plot[M[_]](
            x: source.Column[M, Double], y: source.Column[M, Double],
            line_color: Color,
            _xdr: Option[Range]=None, _ydr: Option[Range]=None) = {

        val xdr = _xdr getOrElse new DataRange1d().sources(x :: Nil)
        val ydr = _ydr getOrElse new DataRange1d().sources(y :: Nil)

        val plot = new Plot().x_range(xdr).y_range(ydr)

        val xaxis = new LinearAxis().plot(plot)
        val yaxis = new LinearAxis().plot(plot)
        plot.below <<= (xaxis :: _)
        plot.left <<= (yaxis :: _)

        val pantool = new PanTool().plot(plot)
        val wheelzoomtool = new WheelZoomTool().plot(plot)

        val renderer = new GlyphRenderer()
            .data_source(source)
            .glyph(new Line().x(x).y(y).line_color(line_color))

        plot.renderers := List(xaxis, yaxis, renderer)
        plot.tools := List(pantool, wheelzoomtool)

        plot
    }

    import source.{x,y1,y2,y3,y4}

    val plot1 = make_plot(x, y1, Color.Blue)
    val plot2 = make_plot(x, y2, Color.Red, _xdr=plot1.x_range.valueOpt)
    val plot3 = make_plot(x, y3, Color.Green)
    val plot4 = make_plot(x, y4, Color.Black)

    val children = List(List(plot1, plot2), List(plot3, plot4))
    val grid = new GridPlot().children(children)

    val document = new Document(grid)
    val html = document.save("grid.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import breeze.linalg.DenseVector

object Hover extends Example with LinAlg with Tools {
    val (xx, yy) = meshgrid(0.0 to 100.0 by 4.0,
                            0.0 to 100.0 by 4.0)

    object source extends ColumnDataSource {
        val x      = column(xx.flatten())
        val y      = column(yy.flatten())
        val inds   = column(x.value.mapPairs { (k, _) => k.toString } toArray)
        val radii  = column(DenseVector.rand(x.value.length)*0.4 + 1.7)
        val colors = column {
            val reds = (x.value*2.0 + 50.0).map(_.toInt).toArray
            val greens = (y.value*2.0 + 30.0).map(_.toInt).toArray
            reds.zip(greens).map { case (r, g) => RGB(r, g, 150): Color }
        }
    }

    import source.{x,y,inds,radii,colors}

    val xdr = new DataRange1d().sources(x :: Nil)
    val ydr = new DataRange1d().sources(y :: Nil)

    val plot = new Plot()
        .title("Color Scatter Example")
        .x_range(xdr)
        .y_range(ydr)
        .tools(Pan|WheelZoom|BoxZoom|Reset|PreviewSave)

    val circle = new Circle()
        .x(x)
        .y(y)
        .radius(radii)
        .fill_color(colors)
        .fill_alpha(0.6)
        .line_color()

    val circle_renderer = new GlyphRenderer()
        .data_source(source)
        .glyph(circle)

    val text = new Text()
        .x(x)
        .y(y)
        .text(inds)
        .angle(0.0)
        .text_alpha(0.5)
        .text_font_size(5 pt)
        .text_baseline(TextBaseline.Middle)
        .text_align(TextAlign.Center)

    val text_renderer = new GlyphRenderer()
        .data_source(source)
        .glyph(text)

    val hover = new HoverTool()
        .tooltips(Tooltip(
            "index"         -> "$index",
            "fill_color"    -> "$color[hex,swatch]:fill_color",
            "radius"        -> "@radii",
            "data (x, y)"   -> "(@x, @y)",
            "cursor (x, y)" -> "($x, $y)",
            "canvas (x, y)" -> "($sx, $sy)"))

    val xaxis = new LinearAxis().plot(plot)
    val yaxis = new LinearAxis().plot(plot)
    plot.below <<= (xaxis :: _)
    plot.left <<= (yaxis :: _)

    plot.renderers := List(xaxis, yaxis, circle_renderer, text_renderer)
    plot.tools <<= (_ :+ hover)

    val document = new Document(plot)
    val html = document.save("hover.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}

import breeze.linalg.linspace
import breeze.numerics.{sin,cos}

object Image extends Example with LinAlg {
    val N = 500

    val x = linspace(0, 10, N)
    val y = linspace(0, 10, N)
    val (xx, yy) = meshgrid(x, y)
    val data = sin(xx) :* cos(yy)

    val xdr = new Range1d().start(0).end(10)
    val ydr = new Range1d().start(0).end(10)

    val plot = new Plot().x_range(xdr).y_range(ydr).title("Image plot with Spectral11 palette")

    val mapper = new LinearColorMapper().palette(Palette.Spectral11)
    val image = new Image().image(data).x(0).y(0).dw(10).dh(10).color_mapper(mapper)
    plot.addGlyph(image)

    val document = new Document(plot)
    val html = document.save("image.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}

import breeze.linalg.linspace

object ImageURL extends Example {
    val url = "http://bokeh.pydata.org/en/latest/_static/bokeh-transparent.png"
    val N = 5

    object source extends ColumnDataSource {
        val urls = column(List(url)*N)
        val x1   = column(linspace(  0, 150, N))
        val y1   = column(linspace(  0, 150, N))
        val w1   = column(linspace( 10,  50, N))
        val h1   = column(linspace( 10,  50, N))
        val x2   = column(linspace(-50, 150, N))
        val y2   = column(linspace(  0, 200, N))
    }

    import source.{urls,x1,y1,w1,h1,x2,y2}

    val xdr = new Range1d().start(-100).end(200)
    val ydr = new Range1d().start(-100).end(200)

    val plot = new Plot().title("ImageURL").x_range(xdr).y_range(ydr)

    val image1 = new ImageURL().url(urls).x(x1).y(y1).w(w1).h(h1).anchor(Anchor.Center)
    plot.addGlyph(source, image1)

    val image2 = new ImageURL().url(urls).x(x2).y(y2).w(20).h(20).anchor(Anchor.TopLeft)
    plot.addGlyph(source, image2)

    val image3 = new ImageURL().url(url).x(200).y(-100).anchor(Anchor.BottomRight)
    plot.addGlyph(source, image3)

    val xaxis = new LinearAxis().plot(plot)
    plot.below := xaxis :: Nil

    val yaxis = new LinearAxis().plot(plot)
    plot.left := yaxis :: Nil

    val xgrid = new Grid().plot(plot).dimension(0).ticker(xaxis.ticker.value)
    val ygrid = new Grid().plot(plot).dimension(1).ticker(yaxis.ticker.value)

    plot.renderers <<= (xaxis :: yaxis :: xgrid :: ygrid :: _)

    val document = new Document(plot)
    val html = document.save("image_url.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}


import sampledata.iris.flowers

object Iris extends Example {
    val colormap = Map[String, Color]("setosa" -> Color.Red, "versicolor" -> Color.Green, "virginica" -> Color.Blue)

    object source extends ColumnDataSource {
        val petal_length = column(flowers.petal_length)
        val petal_width  = column(flowers.petal_width)
        val sepal_length = column(flowers.sepal_length)
        val sepal_width  = column(flowers.sepal_width)
        val color        = column(flowers.species.map(colormap))
    }

    import source.{petal_length,petal_width,sepal_length,sepal_width,color}

    val xdr = new DataRange1d().sources(petal_length :: Nil)
    val ydr = new DataRange1d().sources(petal_width :: Nil)

    val circle = new Circle()
        .x(petal_length)
        .y(petal_width)
        .fill_color(color)
        .fill_alpha(0.2)
        .size(10)
        .line_color(color)

    val renderer = new GlyphRenderer()
        .data_source(source)
        .glyph(circle)

    val plot = new Plot().x_range(xdr).y_range(ydr).title("Iris Data")

    val xaxis = new LinearAxis().plot(plot)
        .axis_label("petal length").bounds((1.0, 7.0)).major_tick_in(0)
    val yaxis = new LinearAxis().plot(plot)
        .axis_label("petal width").bounds((0.0, 2.5)).major_tick_in(0)
    plot.below <<= (xaxis :: _)
    plot.left <<= (yaxis :: _)

    val xgrid = new Grid().plot(plot).axis(xaxis).dimension(0)
    val ygrid = new Grid().plot(plot).axis(yaxis).dimension(1)

    val pantool = new PanTool().plot(plot)
    val wheelzoomtool = new WheelZoomTool().plot(plot)

    plot.renderers := List(xaxis, yaxis, xgrid, ygrid, renderer)
    plot.tools := List(pantool, wheelzoomtool)

    val document = new Document(plot)
    val html = document.save("iris.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}

import sampledata.iris.flowers

import math.{Pi=>pi}

object IrisSplom extends Example {
    val colormap = Map("setosa" -> Color.Red, "versicolor" -> Color.Green, "virginica" -> Color.Blue)

    val source = new ColumnDataSource()
        .addColumn('petal_length, flowers.petal_length)
        .addColumn('petal_width, flowers.petal_width)
        .addColumn('sepal_length, flowers.sepal_length)
        .addColumn('sepal_width, flowers.sepal_width)
        .addColumn('color, flowers.species.map(colormap))

    val text_source = new ColumnDataSource()
        .addColumn('xcenter, Array(125))
        .addColumn('ycenter, Array(145))

    val columns = List('petal_length, 'petal_width, 'sepal_width, 'sepal_length)

    val xdr = new DataRange1d().sources(source.columns(columns: _*) :: Nil)
    val ydr = new DataRange1d().sources(source.columns(columns: _*) :: Nil)

    def make_plot(xname: Symbol, yname: Symbol, xax: Boolean=false, yax: Boolean=false, text: Option[String]=None) = {
        val plot = new Plot()
            .x_range(xdr)
            .y_range(ydr)
            .background_fill("#efe8e2")
            .border_fill(Color.White)
            .title("")
            .min_border(2)
            .h_symmetry(false)
            .v_symmetry(false)
            .width(250)
            .height(250)

        val xaxis = new LinearAxis().plot(plot)
        val yaxis = new LinearAxis().plot(plot)
        plot.below <<= (xaxis :: _)
        plot.left <<= (yaxis :: _)

        val xgrid = new Grid().plot(plot).axis(xaxis).dimension(0)
        val ygrid = new Grid().plot(plot).axis(yaxis).dimension(1)

        val axes = List(xax.option(xaxis), yax.option(yaxis)).flatten
        val grids = List(xgrid, ygrid)

        val circle = new Circle()
            .x(xname)
            .y(yname)
            .fill_color('color)
            .fill_alpha(0.2)
            .size(4)
            .line_color('color)

        val renderer = new GlyphRenderer()
            .data_source(source)
            .glyph(circle)

        val pantool = new PanTool().plot(plot)
        val wheelzoomtool = new WheelZoomTool().plot(plot)

        plot.renderers := axes ++ grids ++ List(renderer)
        plot.tools := List(pantool, wheelzoomtool)

        text.foreach { text =>
            val text_glyph = new Text()
                .x('xcenter, SpatialUnits.Screen)
                .y('ycenter, SpatialUnits.Screen)
                .text(text.replaceAll("_", " "))
                .angle(pi/4)
                .text_font_style(FontStyle.Bold)
                .text_baseline(TextBaseline.Top)
                .text_color("#ffaaaa")
                .text_alpha(0.5)
                .text_align(TextAlign.Center)
                .text_font_size(28 pt)
            val text_renderer = new GlyphRenderer()
                .data_source(text_source)
                .glyph(text_glyph)

            plot.renderers := text_renderer :: plot.renderers.value
        }

        plot
    }

    val xattrs = columns
    val yattrs = xattrs.reverse

    val plots: List[List[Plot]] = yattrs.map { y =>
        xattrs.map { x =>
            val xax = y == yattrs.last
            val yax = x == xattrs(0)
            val text = if (x == y) Some(x.name) else None
            make_plot(x, y, xax, yax, text)
        }
    }

    val grid = new GridPlot().children(plots).title("iris_splom")

    val document = new Document(grid)
    val html = document.save("iris_splom.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}


import breeze.linalg.linspace
import breeze.numerics.sin
import math.{Pi=>pi}

object Line extends Example {
    object source extends ColumnDataSource {
        val x = column(linspace(-2*pi, 2*pi, 1000))
        val y = column(sin(x.value))
    }

    import source.{x,y}

    val xdr = new DataRange1d().sources(x :: Nil)
    val ydr = new DataRange1d().sources(y :: Nil)

    val line = new Line().x(x).y(y).line_color(Color.Blue)

    val renderer = new GlyphRenderer()
        .data_source(source)
        .glyph(line)

    val plot = new Plot().x_range(xdr).y_range(ydr)

    val xaxis = new LinearAxis().plot(plot)
    val yaxis = new LinearAxis().plot(plot)
    plot.below <<= (xaxis :: _)
    plot.left <<= (yaxis :: _)

    val pantool = new PanTool().plot(plot)
    val wheelzoomtool = new WheelZoomTool().plot(plot)

    plot.renderers := List(xaxis, yaxis, renderer)
    plot.tools := List(pantool, wheelzoomtool)

    val document = new Document(plot)
    val html = document.save("line.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}

object Maps extends Example {
    val x_range = new Range1d()
    val y_range = new Range1d()

    val map_options = new GMapOptions()
        .lat(30.2861)
        .lng(-97.7394)
        .zoom(15)
        .map_type(MapType.Satellite)

    val plot = new GMapPlot()
        .x_range(x_range)
        .y_range(y_range)
        .map_options(map_options)
        .title("Austin")

    val xaxis = new LinearAxis().plot(plot).axis_label("lat").major_tick_in(0).formatter(new NumeralTickFormatter().format("0.000"))
    plot.addLayout(xaxis, Layout.Below)

    val yaxis = new LinearAxis().plot(plot).axis_label("lon").major_tick_in(0).formatter(new PrintfTickFormatter().format("%.3f"))
    plot.addLayout(yaxis, Layout.Left)

    val select_tool = new BoxSelectTool()
    val overlay = new BoxSelectionOverlay().tool(select_tool)

    plot.renderers <<= (overlay :: _)
    plot.tools <<= (select_tool :: _)

    val pantool = new PanTool().plot(plot)
    val wheelzoomtool = new WheelZoomTool().plot(plot)

    plot.tools <<= (pantool :: wheelzoomtool :: _)

    object source extends ColumnDataSource {
        val lat  = column(Array(30.2861, 30.2855, 30.2869))
        val lon  = column(Array(-97.7394, -97.7390, -97.7405))
        val fill = column(Array[Color](Color.Orange, Color.Blue, Color.Green))
    }

    import source.{lat,lon,fill}

    val circle = new Circle()
        .x(lon)
        .y(lat)
        .fill_color(fill)
        .size(15)
        .line_color(Color.Black)

    val renderer = new GlyphRenderer()
        .data_source(source)
        .glyph(circle)

    plot.renderers <<= (renderer :: _)

    val document = new Document(plot)
    val html = document.save("maps.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}

object Prim extends Example {
    object source extends ColumnDataSource {
        val x = column(1.0 to 6.0 by  1.0)
        val y = column(5.0 to 0.0 by -1.0)
    }

    import source.{x,y}

    val xdr = new Range1d().start(0).end(10)
    val ydr = new Range1d().start(0).end(10)

    def make_plot[T <: Glyph](name: String, glyph: T) = {
        val renderer = new GlyphRenderer()
            .data_source(source)
            .glyph(glyph)

        val plot = new Plot().x_range(xdr).y_range(ydr).title(name)
        val xaxis = new LinearAxis().plot(plot)
        val yaxis = new LinearAxis().plot(plot)
        plot.below <<= (xaxis :: _)
        plot.left <<= (yaxis :: _)
        val xgrid = new Grid().plot(plot).axis(xaxis).dimension(0)
        val ygrid = new Grid().plot(plot).axis(yaxis).dimension(1)

        val pantool = new PanTool().plot(plot)
        val wheelzoomtool = new WheelZoomTool().plot(plot)

        plot.renderers := List(xaxis, yaxis, xgrid, ygrid, renderer)
        plot.tools := List(pantool, wheelzoomtool)

        plot
    }

    val plots = List(
        make_plot("annular_wedge", new AnnularWedge().x(x).y(y).inner_radius(0.2).outer_radius(0.5).start_angle(0.8).end_angle(3.8)),
        make_plot("annulus",       new Annulus().x(x).y(y).inner_radius(0.2).outer_radius(0.5)),
        make_plot("arc",           new Arc().x(x).y(y).radius(0.4).start_angle(0.8).end_angle(3.8)),
        make_plot("circle",        new Circle().x(x).y(y).radius(1)),
        make_plot("oval",          new Oval().x(x).y(y).width(0.5).height(0.8).angle(-0.6)),
        make_plot("ray",           new Ray().x(x).y(y).length(25).angle(0.6)),
        make_plot("rect",          new Rect().x(x).y(y).width(0.5).height(0.8).angle(-0.6)),
        make_plot("text",          new Text().x(x).y(y).text("foo").angle(0.6)),
        make_plot("wedge",         new Wedge().x(x).y(y).radius(0.5).start_angle(0.9).end_angle(3.2)))

    val document = new Document(plots: _*)
    val html = document.save("prim.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}

import sampledata.{sprint,Medal}

object Sprint extends Example {
    // Based on http://www.nytimes.com/interactive/2012/08/05/sports/olympics/the-100-meter-dash-one-race-every-medalist-ever.html

    val abbrev_to_country: PartialFunction[String, String] = {
        case "USA" => "United States"
        case "GBR" => "Britain"
        case "JAM" => "Jamaica"
        case "CAN" => "Canada"
        case "TRI" => "Trinidad and Tobago"
        case "AUS" => "Australia"
        case "GER" => "Germany"
        case "CUB" => "Cuba"
        case "NAM" => "Namibia"
        case "URS" => "Soviet Union"
        case "BAR" => "Barbados"
        case "BUL" => "Bulgaria"
        case "HUN" => "Hungary"
        case "NED" => "Netherlands"
        case "NZL" => "New Zealand"
        case "PAN" => "Panama"
        case "POR" => "Portugal"
        case "RSA" => "South Africa"
        case "EUA" => "United Team of Germany"
    }

    val gold_fill   = "#efcf6d"
    val gold_line   = "#c8a850"
    val silver_fill = "#cccccc"
    val silver_line = "#b0b0b1"
    val bronze_fill = "#c59e8a"
    val bronze_line = "#98715d"

    type PFC = PartialFunction[Medal, Color]

    val fill_color: PFC = { case Medal.Gold => gold_fill case Medal.Silver => silver_fill case Medal.Bronze => bronze_fill }
    val line_color: PFC = { case Medal.Gold => gold_line case Medal.Silver => silver_line case Medal.Bronze => bronze_line }

    val t0 = sprint.time(0)

    object df {
        val name          = sprint.name
        val abbrev        = sprint.country
        val country       = sprint.country.map(abbrev_to_country)
        val medal         = sprint.medal.map(_.name.toLowerCase)
        val year          = sprint.year
        val time          = sprint.time
        val speed         = sprint.time.map(t => 100.0/t)
        val meters_back   = sprint.time.map(t => 100.0*(1.0 - t0/t))
        val medal_fill    = sprint.medal.map(fill_color)
        val medal_line    = sprint.medal.map(line_color)
        val selected_name = (sprint.name, sprint.medal, sprint.year).zipped.map { case (name, medal, year) =>
            if (medal == Medal.Gold && Set(1988, 1968, 1936, 1896).contains(year)) Some(name) else None
        }
    }

    object source extends ColumnDataSource {
        val Name         = column(df.name)
        val Abbrev       = column(df.abbrev)
        val Country      = column(df.country)
        val Medal        = column(df.medal)
        val Year         = column(df.year)
        val Time         = column(df.time)
        val Speed        = column(df.speed)
        val MetersBack   = column(df.meters_back)
        val MedalFill    = column(df.medal_fill)
        val MedalLine    = column(df.medal_line)
        val SelectedName = column(df.selected_name)
    }

    import source.{Abbrev,Country,Medal,Year,Speed,MetersBack,MedalFill,MedalLine,SelectedName}

    val title = "Usain Bolt vs. 116 years of Olympic sprinters"

    val xdr = new Range1d().start(df.meters_back.max+2).end(0)          // XXX: +2 is poor-man's padding (otherwise misses last tick)
    val ydr = new DataRange1d().sources(Year :: Nil).rangepadding(0.05) // XXX: should be 2 years (both sides)

    val plot = new Plot().title(title).x_range(xdr).y_range(ydr).width(1000).height(600).toolbar_location().outline_line_color()

    val xticker = new SingleIntervalTicker().interval(5).num_minor_ticks(0)
    val xaxis = new LinearAxis().plot(plot).ticker(xticker).axis_line_color().major_tick_line_color()
        .axis_label("Meters behind 2012 Bolt").axis_label_text_font_size(10 pt).axis_label_text_font_style(FontStyle.Bold)
    plot.below := xaxis :: Nil
    val xgrid = new Grid().plot(plot).dimension(0).ticker(xaxis.ticker.value).grid_line_dash(DashPattern.Dashed)
    val yticker = new SingleIntervalTicker().interval(12).num_minor_ticks(0)
    val yaxis = new LinearAxis().plot(plot).ticker(yticker).major_tick_in(-5).major_tick_out(10)
    plot.right := yaxis :: Nil

    val medal_glyph = new Circle().x(MetersBack).y('Year).radius(5, SpatialUnits.Screen).fill_color(MedalFill).line_color(MedalLine).fill_alpha(0.5)
    val medal = new GlyphRenderer().data_source(source).glyph(medal_glyph)

    val athlete_glyph = new Text().x(MetersBack).y('Year).x_offset(10).text('SelectedName)
        .text_align(TextAlign.Left).text_baseline(TextBaseline.Middle).text_font_size(9 pt)
    val athlete = new GlyphRenderer().data_source(source).glyph(athlete_glyph)

    val no_olympics_glyph = new Text().x(7.5).y(1942).text("No Olympics in 1940 or 1944")
        .text_align(TextAlign.Center).text_baseline(TextBaseline.Middle).text_font_size(9 pt).text_font_style(FontStyle.Italic).text_color(Color.Silver)
    val no_olympics = new GlyphRenderer().glyph(no_olympics_glyph)

    plot.renderers := xaxis :: yaxis :: xgrid :: medal :: athlete :: no_olympics :: Nil

    val tooltip = Tooltip("""
    <div>
        <span style="font-size: 15px;">@Name</span>&nbsp;
        <span style="font-size: 10px; color: #666;">(@Abbrev)</span>
    </div>
    <div>
        <span style="font-size: 17px; font-weight: bold;">@Time{0.00}</span>&nbsp;
        <span style="font-size: 10px; color: #666;">@Year</span>
    </div>
    <div style="font-size: 11px; color: #666;">@{MetersBack}{0.00} meters behind</div>
    """)

    val hover = new HoverTool().plot(plot).tooltips(tooltip).renderers(medal :: Nil)
    plot.tools := hover :: Nil

    val document = new Document(plot)
    val html = document.save("sprint.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import math.{abs,pow,sin,cos,atan2,sqrt,toRadians,Pi=>pi}
import breeze.linalg.{diff,DenseVector}

import widgets.VBox
import sampledata.mtb.{obiszow_mtb_xcm=>mtb}

object Trail extends Example with Tools {
    def haversin(theta: Double) = pow(sin(0.5*theta), 2)

    def distance(p1: (Double, Double), p2: (Double, Double)): Double = {
        val R = 6371

        val (lat1, lon1) = p1
        val (lat2, lon2) = p2

        val phi1 = toRadians(lat1)
        val phi2 = toRadians(lat2)
        val delta_lat = toRadians(lat2 - lat1)
        val delta_lon = toRadians(lon2 - lon1)

        val a = haversin(delta_lat) + cos(phi1)*cos(phi2)*haversin(delta_lon)
        2*R*atan2(sqrt(a), sqrt(1 - a))
    }

    val dists = (mtb.lat zip mtb.lon)
        .sliding(2).toList
        .map { case List(p1, p2) => distance(p2, p1) }

    val dist = dists.scanLeft(0.0)(_ + _)

    // TODO: val slopes = abs(100*diff(alt)/(1000*dists))
    val slopes = mtb.alt
       .sliding(2).toList
       .map { case List(a1, a2) => a2 - a1 }
       .map(100*_)
       .zip(dists.map(1000*_))
       .map { case (alt, dist) => alt/dist }
       .map(abs)

    val grads = slopes map { slope =>
        if      (               slope <  4) 0
        else if (slope >=  4 && slope <  6) 1
        else if (slope >=  6 && slope < 10) 2
        else if (slope >= 10 && slope < 15) 3
        else                                4
    }

    val colors: Seq[Color] = grads map {
        case 0 => Color.Green
        case 1 => Color.Yellow
        case 2 => Color.Pink
        case 3 => Color.Orange
        case 4 => Color.Red
    }

    val title = "Obiszów MTB XCM"

    val trail_map = {
        val lon = (mtb.lon.min + mtb.lon.max)/2
        val lat = (mtb.lat.min + mtb.lat.max)/2

        val map_options = new GMapOptions().lng(lon).lat(lat).zoom(13)
        val plot = new GMapPlot().title(s"$title - Trail Map").map_options(map_options).width(800).height(800)

        val xaxis = new LinearAxis().plot(plot).formatter(new NumeralTickFormatter().format("0.000"))
        plot.addLayout(xaxis, Layout.Below)

        val yaxis = new LinearAxis().plot(plot).formatter(new PrintfTickFormatter().format("%.3f"))
        plot.addLayout(yaxis, Layout.Left)

        val xgrid = new Grid().plot(plot).dimension(0).ticker(xaxis.ticker.value).grid_line_dash(DashPattern.Dashed).grid_line_color(Color.Gray)
        val ygrid = new Grid().plot(plot).dimension(1).ticker(yaxis.ticker.value).grid_line_dash(DashPattern.Dashed).grid_line_color(Color.Gray)
        plot.renderers <<= (xgrid :: ygrid :: _)

        val hover = new HoverTool().tooltips(Tooltip("distance" -> "@dist"))
        plot.tools := Pan|WheelZoom|Reset|BoxSelect
        plot.tools <<= (hover +: _)

        object line_source extends ColumnDataSource {
            val x = column(mtb.lon)
            val y = column(mtb.lat)
        }

        import line_source.{x,y}

        val line = new Line().x(x).y(y).line_color(Color.Blue).line_width(2)
        plot.addGlyph(line_source, line)

        plot.x_range := new DataRange1d().sources(x :: Nil)
        plot.y_range := new DataRange1d().sources(y :: Nil)

        plot
    }

    val altitude_profile = {
        val plot = new Plot().title(s"$title - Altitude Profile").width(800).height(400)

        val xaxis = new LinearAxis().plot(plot).axis_label("Distance (km)")
        plot.addLayout(xaxis, Layout.Below)

        val yaxis = new LinearAxis().plot(plot).axis_label("Altitude (m)")
        plot.addLayout(yaxis, Layout.Left)

        val xgrid = new Grid().plot(plot).dimension(0).ticker(xaxis.ticker.value)
        val ygrid = new Grid().plot(plot).dimension(1).ticker(yaxis.ticker.value)
        plot.renderers <<= (xgrid :: ygrid :: _)

        plot.tools := Pan|WheelZoom|Reset|BoxSelect

        val (_xs, _ys) = (dist, mtb.alt)
        val y0 = _ys.min

        object patches_source extends ColumnDataSource {
            val xs    = column(_xs.sliding(2).map { case List(xi, xj) => List(xi, xj, xj, xi) } toList)
            val ys    = column(_ys.sliding(2).map { case List(yi, yj) => List(y0, y0, yj, yi) } toList)
            val color = column(colors)
        }

        import patches_source.{xs,ys,color}

        val patches = new Patches().xs(xs).ys(ys).fill_color(color).line_color(color)
        plot.addGlyph(patches_source, patches)

        object line_source extends ColumnDataSource {
            val x = column(dist)
            val y = column(mtb.alt)
        }

        import line_source.{x,y}

        val line = new Line().x(x).y(y).line_color(Color.Black).line_width(1)
        plot.addGlyph(line_source, line)

        plot.x_range := new DataRange1d().sources(x :: Nil)
        plot.y_range := new DataRange1d().sources(y :: Nil)

        plot
    }

    val layout = new VBox().children(List(altitude_profile, trail_map))

    val document = new Document(layout)
    val html = document.save("trail.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}



import breeze.linalg.linspace
import breeze.numerics.sin
import math.{Pi=>pi}

object TwinAxis extends Example with Tools {
    object source extends ColumnDataSource {
        val x  = column(-2*pi to 2*pi by 0.1 toArray)
        val y1 = column(sin(x.value))
        val y2 = column(linspace(0, 100, x.value.length))
    }

    import source.{x,y1,y2}

    val xdr = new Range1d().start(-6.5).end(6.5)
    val ydr = new Range1d().start(-1.1).end(1.1)

    val plot = new Plot()
        .title("Twin Axis Plot")
        .x_range(xdr)
        .y_range(ydr)
        .min_border(80)
        .tools(Pan|WheelZoom)
        .extra_y_ranges(Map("foo" -> new Range1d().start(0).end(100)))

    val xaxis = new LinearAxis().plot(plot)
    val y1axis = new LinearAxis().plot(plot)
    val y2axis = new LinearAxis().plot(plot).y_range_name("foo")

    plot.below := xaxis :: Nil
    plot.left  := y1axis :: y2axis :: Nil

    val circle1_glyph = new Circle().x(x).y(y1).fill_color(Color.Red).size(5).line_color(Color.Black)
    val circle1 = new GlyphRenderer().data_source(source).glyph(circle1_glyph)

    val circle2_glyph = new Circle().x(x).y(y2).fill_color(Color.Blue).size(5).line_color(Color.Black)
    val circle2 = new GlyphRenderer().data_source(source).glyph(circle2_glyph).y_range_name("foo")

    plot.renderers := xaxis :: y1axis :: y2axis :: circle1 :: circle2 :: Nil

    val document = new Document(plot)
    val html = document.save("twin_axis.html", config.resources)
    info(s"Wrote ${html.file}. Open ${html.url} in a web browser.")
}
