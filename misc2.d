
abstract class Widget extends PlotObject {
    object disabled extends Field[Boolean](false)
}



class ToolEvents extends PlotObject {
    object geometries extends Field[List[Map[Symbol, Any]]]
}

sealed abstract class Tool extends PlotObject {
    object plot extends Field[Plot]
}

class PanTool extends Tool {
    object dimensions extends Field[List[Dimension]](List(Dimension.Width, Dimension.Height))
}

class WheelZoomTool extends Tool {
    object dimensions extends Field[List[Dimension]](List(Dimension.Width, Dimension.Height))
}

class PreviewSaveTool extends Tool

class ResetTool extends Tool

class ResizeTool extends Tool

class CrosshairTool extends Tool

class BoxZoomTool extends Tool

abstract class TransientSelectTool extends Tool {
    object names extends Field[List[String]]
    object renderers extends Field[List[Renderer]]
}

abstract class SelectTool extends TransientSelectTool

class BoxSelectTool extends SelectTool {
    object select_every_mousemove extends Field[Boolean](true)
    object dimensions extends Field[List[Dimension]](List(Dimension.Width, Dimension.Height))
}

class LassoSelectTool extends SelectTool {
    object select_every_mousemove extends Field[Boolean](true)
}

class PolySelectTool extends SelectTool

class TapTool extends SelectTool {
    object action extends Field[Action]
    object always_active extends Field[Boolean](true)
}

class HoverTool extends TransientSelectTool {
    object tooltips extends Field[Tooltip]
    object always_active extends Field[Boolean](true)
    object snap_to_data extends Field[Boolean](true)
}




abstract class Ticker extends PlotObject {
    object num_minor_ticks extends Field[Int](5)
}

class AdaptiveTicker extends Ticker {
    object base extends Field[Double](10.0)
    object mantissas extends Field[List[Double]](List(2, 5, 10))
    object min_interval extends Field[Double](0.0)
    object max_interval extends Field[Double](100.0)
}

class CompositeTicker extends Ticker {
    object tickers extends Field[List[Ticker]]
}

class SingleIntervalTicker extends Ticker {
    object interval extends Field[Double]
}

class DaysTicker extends SingleIntervalTicker {
    object days extends Field[List[Int]]
}

class MonthsTicker extends SingleIntervalTicker {
    object months extends Field[List[Int]]
}

class YearsTicker extends SingleIntervalTicker

class BasicTicker extends Ticker

class LogTicker extends AdaptiveTicker

class CategoricalTicker extends Ticker

class DatetimeTicker extends Ticker

abstract class TickFormatter extends PlotObject

class BasicTickFormatter extends TickFormatter {
    // TODO: object precision extends Field[Either[Auto, Int]]
    object use_scientific extends Field[Boolean](true)
    object power_limit_high extends Field[Int](5)
    object power_limit_low extends Field[Int](-3)
}

class LogTickFormatter extends TickFormatter

class CategoricalTickFormatter extends TickFormatter

class DatetimeTickFormatter extends TickFormatter {
    object formats extends Field[Map[DatetimeUnits, List[String]]]
}

class NumeralTickFormatter extends TickFormatter {
    object format extends Field[String]("0,0")
    object language extends Field[NumeralLanguage]
    object rounding extends Field[RoundingFunction]
}

class PrintfTickFormatter extends TickFormatter {
    object format extends Field[String]("%s")
}



import play.api.libs.json.Writes

class ColumnsRef extends HasFields {
    object source extends Field[DataSource]
    object columns extends Field[List[Symbol]]
}

abstract class DataSource extends PlotObject {
    object column_names extends Field[List[String]]
    object selected extends Field[List[Int]]

    def columns(columns: Symbol*): ColumnsRef =
        new ColumnsRef().source(this).columns(columns.toList)
}

class ColumnDataSource extends DataSource { source =>
    final override val typeName = "ColumnDataSource"

    object data extends Field[Map[Symbol, Any]]

    class Column[M[_]: ArrayLike, T](val name: Symbol, _value: M[T]) {
        this := _value

        def value: M[T] = source.data.value(name).asInstanceOf[M[T]]
        def :=(value: M[T]): Unit = source.addColumn(name, value)

        def ref: ColumnsRef = new ColumnsRef().source(source).columns(name :: Nil)
    }

    def column[M[_], T](value: M[T]): ColumnDataSource#Column[M, T] = macro ColumnMacro.columnImpl[M, T]

    def addColumn[M[_]: ArrayLike, T](name: Symbol, value: M[T]): SelfType = {
        data <<= (_ + (name -> value))
        this
    }
}

trait SourceImplicits {
    implicit def ColumnToColumnsRef[M[_]](column: ColumnDataSource#Column[M, _]): ColumnsRef = column.ref
}

private[bokeh] object ColumnMacro {
    import scala.reflect.macros.Context

    def columnImpl[M[_], T](c: Context)(value: c.Expr[M[T]])
            (implicit ev1: c.WeakTypeTag[M[_]], ev2: c.WeakTypeTag[T]): c.Expr[ColumnDataSource#Column[M, T]] = {
        import c.universe._

        val name = definingValName(c).map(name => c.Expr[String](Literal(Constant(name)))) getOrElse {
            c.abort(c.enclosingPosition, "column must be directly assigned to a val, such as `val x1 = column(List(1.0, 2.0, 3.0))`")
        }

        c.Expr[ColumnDataSource#Column[M, T]](q"new Column(Symbol($name), $value)")
    }

    def definingValName(c: Context): Option[String] = {
        import c.universe._

        c.enclosingClass.collect {
            case ValDef(_, name, _, rhs) if rhs.pos == c.macroApplication.pos => name.encoded
        }.headOption
    }
}

abstract class RemoteSource extends DataSource {
    object data_url extends Field[String]
    object polling_interval extends Field[Int]
}

class AjaxDataSource extends RemoteSource {
    object method extends Field[HTTPMethod](HTTPMethod.POST)
}



abstract class Renderer extends PlotObject

class GlyphRenderer extends Renderer {
    // TODO: object server_data_source extends Field[ServerDataSource]
    object data_source extends Field[DataSource](new ColumnDataSource())

    object glyph extends Field[Glyph]
    object selection_glyph extends Field[Glyph]
    object nonselection_glyph extends Field[Glyph]

    object x_range_name extends Field[String]("default")
    object y_range_name extends Field[String]("default")
}

class Legend extends Renderer {
    object plot extends Field[Plot]

    object orientation extends Field[LegendOrientation]
    border = include[LineProps]

    object label_standoff extends Field[Int](15)
    object label_height extends Field[Int](20)
    object label_width extends Field[Int](50)
    label = include[TextProps]

    object glyph_height extends Field[Int](20)
    object glyph_width extends Field[Int](20)

    object legend_padding extends Field[Int](10)
    object legend_spacing extends Field[Int](3)

    object legends extends Field[List[(String, List[GlyphRenderer])]]
}

class BoxSelectionOverlay extends Renderer {
    override val typeName = "BoxSelection"

    object tool extends Field[BoxSelectTool]
}



abstract class Range extends PlotObject

class Range1d extends Range {
    object start extends Field[Double]
    object end extends Field[Double]
}

abstract class DataRange extends Range {
    object sources extends Field[List[ColumnsRef]]
}

class DataRange1d extends DataRange {
    object rangepadding extends Field[Double](0.1)

    object start extends Field[Double]
    object end extends Field[Double]
}

class FactorRange extends Range {
    object factors extends Field[List[String]] // TODO: also List[Int]
}




class Plot extends Widget {
    object title extends Field[String]("")

    title = include[TextProps]
    outline = include[LineProps]

    object x_range extends Field[Range]
    object y_range extends Field[Range]

    object extra_x_ranges extends Field[Map[String, Range]]
    object extra_y_ranges extends Field[Map[String, Range]]

    object x_mapper_type extends Field[String]("auto")
    object y_mapper_type extends Field[String]("auto")

    object renderers extends Field[List[Renderer]]
    object tools extends Field[List[Tool]] with ToolsField

    object tool_events extends Field[ToolEvents](new ToolEvents())

    object left extends Field[List[Renderer]]
    object right extends Field[List[Renderer]]
    object above extends Field[List[Renderer]]
    object below extends Field[List[Renderer]]

    object toolbar_location extends Field[Location](Location.Above)
    object logo extends Field[Logo](Logo.Normal)

    object plot_width extends Field[Int](600)
    object plot_height extends Field[Int](600)

    def width = plot_width
    def height = plot_height

    object background_fill extends Field[Color](Color.White)
    object border_fill extends Field[Color](Color.White)

    object min_border_top extends Field[Int]
    object min_border_bottom extends Field[Int]
    object min_border_left extends Field[Int]
    object min_border_right extends Field[Int]
    object min_border extends Field[Int]

    object h_symmetry extends Field[Boolean](true)
    object v_symmetry extends Field[Boolean](false)

    def addGlyph(glyph: Glyph): GlyphRenderer = {
        addGlyph(new ColumnDataSource(), glyph)
    }

    def addGlyph(source: DataSource, glyph: Glyph): GlyphRenderer = {
        val renderer = new GlyphRenderer().data_source(source).glyph(glyph)
        renderers <<= (_ :+ renderer)
        renderer
    }

    def addLayout(renderer: Renderer, layout: Layout): Renderer = {
        layout match {
            case Layout.Left   => left  <<= (renderer +: _)
            case Layout.Right  => right <<= (renderer +: _)
            case Layout.Above  => above <<= (renderer +: _)
            case Layout.Below  => below <<= (renderer +: _)
            case Layout.Center =>
        }
        renderers <<= (_ :+ renderer)
        renderer
    }
}



trait ByReference { self: HasFields =>
    type RefType

    def getRef: RefType
    def id: AbstractField { type ValueType = String }
}

case class Ref(id: String, `type`: String)

abstract class PlotObject extends HasFields with ByReference {
    type RefType = Ref

    def getRef = Ref(id.value, typeName)
    object id extends Field[String](IdGenerator.next())
}



class PlotContext extends PlotObject {
    object children extends Field[List[Widget]]
}




sealed abstract class Marker extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object size extends Spatial[Double](SpatialUnits.Screen) with NonNegative
}

class Asterisk extends Marker

class Circle extends Marker {
    object radius extends Spatial[Double](SpatialUnits.Data) with NonNegative
    object radius_dimension extends Field[Dimension]
}

class CircleCross extends Marker

class CircleX extends Marker

class Cross extends Marker

class Diamond extends Marker

class DiamondCross extends Marker

class InvertedTriangle extends Marker

class Square extends Marker {
    object angle extends Angular[Double]
}

class SquareCross extends Marker

class SquareX extends Marker

class Triangle extends Marker

class PlainX extends Marker {
    override val typeName = "X"
}

abstract class ColorMapper extends PlotObject

class LinearColorMapper extends ColorMapper {
    object palette extends Field[Seq[Color]](Palette.Greys9)

    object low extends Field[Double]
    object high extends Field[Double]

    object reserve_color extends Field[Color](Color.Transparent)
    object reserve_val extends Field[Double]
}




abstract class MapOptions extends HasFields {
    object lat extends Field[Double]
    object lng extends Field[Double]
    object zoom extends Field[Int](12)
}

abstract class MapPlot extends Plot

class GMapOptions extends MapOptions {
    object map_type extends Field[MapType]
}

class GMapPlot extends MapPlot {
    object map_options extends Field[GMapOptions]
}

class GeoJSOptions extends MapOptions

class GeoJSPlot extends MapPlot {
    object map_options extends Field[GeoJSOptions]
}




abstract class GuideRenderer extends Renderer {
    object plot extends Field[Plot]
    object bounds extends Field[(Double, Double)] // TODO: Either[Auto, (Float, Float)]]

    object x_range_name extends Field[String]("default")
    object y_range_name extends Field[String]("default")
}

abstract class Axis extends GuideRenderer {
    object visible extends Field[Boolean](true)
    object location extends Field[Location]

    def defaultTicker: Ticker
    def defaultFormatter: TickFormatter

    object ticker extends Field[Ticker](defaultTicker)
    object formatter extends Field[TickFormatter](defaultFormatter)

    object axis_label extends Field[String]
    object axis_label_standoff extends Field[Int]
    axis_label = include[TextProps]

    object major_label_standoff extends Field[Int]
    object major_label_orientation extends Field[Orientation] // TODO: Either[Orientation, Double]
    major_label = include[TextProps]

    axis = include[LineProps]

    major_tick = include[LineProps]
    object major_tick_in extends Field[Int]
    object major_tick_out extends Field[Int]

    minor_tick = include[LineProps]
    object minor_tick_in extends Field[Int]
    object minor_tick_out extends Field[Int]
}

abstract class ContinuousAxis extends Axis

class LinearAxis extends ContinuousAxis {
    def defaultTicker: Ticker = new BasicTicker()
    def defaultFormatter: TickFormatter = new BasicTickFormatter()
}

class LogAxis extends ContinuousAxis {
    def defaultTicker: Ticker = new LogTicker().num_minor_ticks(10)
    def defaultFormatter: TickFormatter = new LogTickFormatter()
}

class CategoricalAxis extends Axis {
    def defaultTicker: Ticker = new CategoricalTicker()
    def defaultFormatter: TickFormatter = new CategoricalTickFormatter()
}

class DatetimeAxis extends LinearAxis {
    override def defaultTicker: Ticker = new DatetimeTicker()
    override def defaultFormatter: TickFormatter = new DatetimeTickFormatter()

    object scale extends Field[String]("time")
    object num_labels extends Field[Int](8)
    object char_width extends Field[Int](10)
    object fill_ratio extends Field[Double](0.3)
}

class Grid extends GuideRenderer {
    object dimension extends Field[Int](0)
    object ticker extends Field[Ticker]

    def axis(axis: Axis): SelfType = {
        axis.ticker.valueOpt.foreach(this.ticker := _)
        this
    }

    grid = include[LineProps]
}




class GridPlot extends Plot {
    object children extends Field[List[List[Plot]]]
    object border_space extends Field[Int](0)
}




abstract class Glyph extends PlotObject with Vectorization {
    object visible extends Field[Boolean](true)
}

class AnnularWedge extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object inner_radius extends Spatial[Double] with NonNegative
    object outer_radius extends Spatial[Double] with NonNegative
    object start_angle extends Angular[Double]
    object end_angle extends Angular[Double]
    object direction extends Field[Direction]
}

class Annulus extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object inner_radius extends Spatial[Double] with NonNegative
    object outer_radius extends Spatial[Double] with NonNegative
}

class Arc extends Glyph with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object radius extends Spatial[Double] with NonNegative
    object start_angle extends Angular[Double]
    object end_angle extends Angular[Double]
    object direction extends Field[Direction]
}

class Bezier extends Glyph with LineProps {
    object x0 extends Spatial[Double]
    object y0 extends Spatial[Double]
    object x1 extends Spatial[Double]
    object y1 extends Spatial[Double]
    object cx0 extends Spatial[Double]
    object cy0 extends Spatial[Double]
    object cx1 extends Spatial[Double]
    object cy1 extends Spatial[Double]
}

class ImageRGBA extends Glyph {
    object image extends Vectorized[Array[Double]]
    object rows extends Vectorized[Int]
    object cols extends Vectorized[Int]
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object dw extends Spatial[Double] with NonNegative
    object dh extends Spatial[Double] with NonNegative
    object dilate extends Field[Boolean]

    def image[T[_]: MatrixLike](value: T[Double]): SelfType = {
        val (image, rows, cols) = implicitly[MatrixLike[T]].data(value)

        this.image := image
        this.rows  := rows
        this.cols  := cols

        this
    }
}

class Image extends ImageRGBA {
    object color_mapper extends Field[ColorMapper]
}

class ImageURL extends Glyph {
    object url extends Vectorized[String]
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object w extends Spatial[Double] with NonNegative
    object h extends Spatial[Double] with NonNegative
    object angle extends Angular[Double]
    object dilate extends Field[Boolean]
    object anchor extends Field[Anchor]
}

class Line extends Glyph with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
}

class MultiLine extends Glyph with LineProps {
    object xs extends Spatial[List[Double]]
    object ys extends Spatial[List[Double]]
}

class Oval extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object width extends Spatial[Double] with NonNegative
    object height extends Spatial[Double] with NonNegative
    object angle extends Angular[Double]
}

class Patch extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
}

class Patches extends Glyph with LineProps with FillProps {
    object xs extends Spatial[List[Double]]
    object ys extends Spatial[List[Double]]
}

class Quad extends Glyph with FillProps with LineProps {
    object left extends Spatial[Double]
    object right extends Spatial[Double]
    object bottom extends Spatial[Double]
    object top extends Spatial[Double]
}

class Quadratic extends Glyph with LineProps {
    object x0 extends Spatial[Double]
    object y0 extends Spatial[Double]
    object x1 extends Spatial[Double]
    object y1 extends Spatial[Double]
    object cx extends Spatial[Double]
    object cy extends Spatial[Double]
}

class Ray extends Glyph with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object angle extends Angular[Double]
    object length extends Spatial[Double](SpatialUnits.Screen) with NonNegative
}

class Rect extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object width extends Spatial[Double] with NonNegative
    object height extends Spatial[Double] with NonNegative
    object angle extends Angular[Double]
    object dilate extends Field[Boolean]
}

class Segment extends Glyph with LineProps {
    object x0 extends Spatial[Double]
    object y0 extends Spatial[Double]
    object x1 extends Spatial[Double]
    object y1 extends Spatial[Double]
}

class Text extends Glyph with TextProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object text extends Vectorized[String]
    object angle extends Angular[Double](0)
    object x_offset extends Spatial[Double](0, SpatialUnits.Screen)
    object y_offset extends Spatial[Double](0, SpatialUnits.Screen)
}

class Wedge extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object radius extends Spatial[Double] with NonNegative
    object start_angle extends Angular[Double]
    object end_angle extends Angular[Double]
    object direction extends Field[Direction]
}

class Gear extends Glyph with LineProps with FillProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object angle extends Angular[Double]
    object module extends Spatial[Double] with NonNegative
    object teeth extends Vectorized[Int] // TODO: with NonNegative
    object pressure_angle extends Angular[Double](20, AngularUnits.Deg)
    object shaft_size extends Spatial[Double](0.3) with NonNegative
    object internal extends Vectorized[Boolean](false)
}



abstract class Action extends PlotObject

class OpenURL extends Action {
    object url extends Field[String]("http://")
}


package widgets

abstract class AbstractButton extends Widget {
    object label extends Field[String]("Button")
    object icon extends Field[AbstractIcon]
    object `type` extends Field[ButtonType]
}

class Button extends AbstractButton {
    object clicks extends Field[Int](0)
}

class Toggle extends AbstractButton {
    object active extends Field[Boolean](false)
}

class Dropdown extends AbstractButton {
    object action extends Field[String]
    object default_action extends Field[String]
    object menu extends Field[List[(String, String)]]
}


package widgets

class Dialog extends Widget {
    object visible extends Field[Boolean](false)
    object closable extends Field[Boolean](true)
    object title extends Field[String]
    object content extends Field[String]
    object buttons extends Field[List[String]]
}


package widgets

abstract class AbstractGroup extends Widget {
    object labels extends Field[List[String]]
}

abstract class Group extends AbstractGroup {
    object inline extends Field[Boolean](false)
}

abstract class ButtonGroup extends AbstractGroup {
    object `type` extends Field[ButtonType]
}

class CheckboxGroup extends Group {
    object active extends Field[List[Int]]
}

class RadioGroup extends Group {
    object active extends Field[Int]
}

class CheckboxButtonGroup extends ButtonGroup {
    object active extends Field[List[Int]]
}

class RadioButtonGroup extends ButtonGroup {
    object active extends Field[Int]
}


package widgets

abstract class AbstractIcon extends Widget

class Icon extends AbstractIcon {
    object name extends Field[NamedIcon]
    object size extends Field[Double] with NonNegative
    object flip extends Field[Flip]
    object spin extends Field[Boolean](false)
}


package widgets

import org.joda.time.{LocalDate=>Date}
import play.api.libs.json.Writes

abstract class InputWidget[T:Default:Writes] extends Widget {
    object title extends Field[String]
    object name extends Field[String]
    object value extends Field[T]
}

class TextInput extends InputWidget[String]

class AutocompleteInput extends TextInput {
    object completions extends Field[List[String]]
}

class Select extends InputWidget[String] {
    object options extends Field[List[String]]
}

class Slider extends InputWidget[Double] {
    object start extends Field[Double]
    object end extends Field[Double]
    object step extends Field[Double]
    object orientation extends Field[Orientation]
}

class DateRangeSlider extends InputWidget[(Date, Date)] {
    object bounds extends Field[(Date, Date)]
    // TODO: object range extends Field[(RelativeDelta, RelativeDelta)]
    // TODO: object step extends Field[RelativeDelta
    // TODO: object formatter extends Field[Either[String, Function[Date]]]
    // TODO: object scales extends Field[DateRangeSliderScales] ... first, next, stop, label, format
    object enabled extends Field[Boolean](true)
    object arrows extends Field[Boolean](true)
    // TODO: object value_labels extends Field[] // Enum("show", "hide", "change")
    // TODO: object wheel_mode extends OptionalField[] // Enum("scroll", "zoom", default=None)
}

class DatePicker extends InputWidget[Date] {
    // TODO: object min_date extends OptionalField[Date]
    // TODO: object max_date extends OptionalField[Date]
}
package widgets

abstract class Layout extends Widget {
    object width extends Field[Int]
    object height extends Field[Int]
}

class HBox extends Layout {
    object children extends Field[List[Widget]]
}

class VBox extends Layout {
    object children extends Field[List[Widget]]
}
package widgets

class Paragraph extends Widget {
    object text extends Field[String]
}

class PreText extends Paragraph
package widgets

class Panel extends Widget {
    object title extends Field[String]
    object child extends Field[Widget]
    object closable extends Field[Boolean](false)
}

class Tabs extends Widget {
    object tabs extends Field[List[Panel]]
    object active extends Field[Int](0)
}
package widgets

abstract class CellFormatter extends PlotObject

abstract class CellEditor extends PlotObject

class StringFormatter extends CellFormatter {
    object font_style extends Field[FontStyle]
    object text_align extends Field[TextAlign]
    object text_color extends Field[Color]
}

class NumberFormatter extends StringFormatter {
    object format extends Field[String]("0,0")
    object language extends Field[NumeralLanguage]
    object rounding extends Field[RoundingFunction]
}

class BooleanFormatter extends CellFormatter {
    object icon extends Field[Checkmark]
}

class DateFormatter extends CellFormatter {
    /** The format can be combinations of the following:

       `d`     - day of month (no leading zero)
       `dd`    - day of month (two digit)
       `o`     - day of year (no leading zeros)
       `oo`    - day of year (three digit)
       `D`     - day name short
       `DD`    - day name long
       `m`     - month of year (no leading zero)
       `mm`    - month of year (two digit)
       `M`     - month name short
       `MM`    - month name long
       `y`     - year (two digit)
       `yy`    - year (four digit)
       `@`     - Unix timestamp (ms since 01/01/1970)
       `!`     - Windows ticks (100ns since 01/01/0001)
       `"..."` - literal text
       `''`    - single quote
     */
    object format extends Field[String]("yy M d") // TODO: Enum(DateFormat)
}

class StringEditor extends CellEditor {
    object completions extends Field[List[String]]
}

class TextEditor extends CellEditor

class SelectEditor extends CellEditor {
    object options extends Field[List[String]]
}

class PercentEditor extends CellEditor

class CheckboxEditor extends CellEditor

class IntEditor extends CellEditor {
    object step extends Field[Int](1)
}

class NumberEditor extends CellEditor {
    object step extends Field[Double](0.01)
}

class TimeEditor extends CellEditor

class DateEditor extends CellEditor

class TableColumn extends PlotObject {
    object field extends Field[Symbol]
    object title extends Field[String]
    object width extends Field[Int](300)          // px
    object formatter extends Field[CellFormatter] // lambda: StringFormatter())
    object editor extends Field[CellEditor]       // lambda: StringEditor())
    object sortable extends Field[Boolean](true)
    object default_sort extends Field[Sort]
}

abstract class TableWidget extends Widget {
    object source extends Field[DataSource]
}

class DataTable extends TableWidget {
    object columns extends Field[List[TableColumn]]
    object width extends Field[Int]                     // TODO: None       // px, optional
    object height extends Field[Int](400)               // TODO: Auto       // px, required, use "auto" only for small data
    object fit_columns extends Field[Boolean](true)
    object sortable extends Field[Boolean](true)
    object editable extends Field[Boolean](false)
    object selectable extends Field[Boolean](true)      // TODO: Enum("checkbox"))
    object row_headers extends Field[Boolean](true)
}


abstract class Action extends PlotObject

class OpenURL extends Action {
    object url extends Field[String]("http://")
}



abstract class Glyph extends PlotObject with Vectorization {
    object visible extends Field[Boolean](true)
}

class AnnularWedge extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object inner_radius extends Spatial[Double] with NonNegative
    object outer_radius extends Spatial[Double] with NonNegative
    object start_angle extends Angular[Double]
    object end_angle extends Angular[Double]
    object direction extends Field[Direction]
}

class Annulus extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object inner_radius extends Spatial[Double] with NonNegative
    object outer_radius extends Spatial[Double] with NonNegative
}

class Arc extends Glyph with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object radius extends Spatial[Double] with NonNegative
    object start_angle extends Angular[Double]
    object end_angle extends Angular[Double]
    object direction extends Field[Direction]
}

class Bezier extends Glyph with LineProps {
    object x0 extends Spatial[Double]
    object y0 extends Spatial[Double]
    object x1 extends Spatial[Double]
    object y1 extends Spatial[Double]
    object cx0 extends Spatial[Double]
    object cy0 extends Spatial[Double]
    object cx1 extends Spatial[Double]
    object cy1 extends Spatial[Double]
}

class ImageRGBA extends Glyph {
    object image extends Vectorized[Array[Double]]
    object rows extends Vectorized[Int]
    object cols extends Vectorized[Int]
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object dw extends Spatial[Double] with NonNegative
    object dh extends Spatial[Double] with NonNegative
    object dilate extends Field[Boolean]

    def image[T[_]: MatrixLike](value: T[Double]): SelfType = {
        val (image, rows, cols) = implicitly[MatrixLike[T]].data(value)

        this.image := image
        this.rows  := rows
        this.cols  := cols

        this
    }
}

class Image extends ImageRGBA {
    object color_mapper extends Field[ColorMapper]
}

class ImageURL extends Glyph {
    object url extends Vectorized[String]
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object w extends Spatial[Double] with NonNegative
    object h extends Spatial[Double] with NonNegative
    object angle extends Angular[Double]
    object dilate extends Field[Boolean]
    object anchor extends Field[Anchor]
}

class Line extends Glyph with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
}

class MultiLine extends Glyph with LineProps {
    object xs extends Spatial[List[Double]]
    object ys extends Spatial[List[Double]]
}

class Oval extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object width extends Spatial[Double] with NonNegative
    object height extends Spatial[Double] with NonNegative
    object angle extends Angular[Double]
}

class Patch extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
}

class Patches extends Glyph with LineProps with FillProps {
    object xs extends Spatial[List[Double]]
    object ys extends Spatial[List[Double]]
}

class Quad extends Glyph with FillProps with LineProps {
    object left extends Spatial[Double]
    object right extends Spatial[Double]
    object bottom extends Spatial[Double]
    object top extends Spatial[Double]
}

class Quadratic extends Glyph with LineProps {
    object x0 extends Spatial[Double]
    object y0 extends Spatial[Double]
    object x1 extends Spatial[Double]
    object y1 extends Spatial[Double]
    object cx extends Spatial[Double]
    object cy extends Spatial[Double]
}

class Ray extends Glyph with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object angle extends Angular[Double]
    object length extends Spatial[Double](SpatialUnits.Screen) with NonNegative
}

class Rect extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object width extends Spatial[Double] with NonNegative
    object height extends Spatial[Double] with NonNegative
    object angle extends Angular[Double]
    object dilate extends Field[Boolean]
}

class Segment extends Glyph with LineProps {
    object x0 extends Spatial[Double]
    object y0 extends Spatial[Double]
    object x1 extends Spatial[Double]
    object y1 extends Spatial[Double]
}

class Text extends Glyph with TextProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object text extends Vectorized[String]
    object angle extends Angular[Double](0)
    object x_offset extends Spatial[Double](0, SpatialUnits.Screen)
    object y_offset extends Spatial[Double](0, SpatialUnits.Screen)
}

class Wedge extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object radius extends Spatial[Double] with NonNegative
    object start_angle extends Angular[Double]
    object end_angle extends Angular[Double]
    object direction extends Field[Direction]
}

class Gear extends Glyph with LineProps with FillProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object angle extends Angular[Double]
    object module extends Spatial[Double] with NonNegative
    object teeth extends Vectorized[Int] // TODO: with NonNegative
    object pressure_angle extends Angular[Double](20, AngularUnits.Deg)
    object shaft_size extends Spatial[Double](0.3) with NonNegative
    object internal extends Vectorized[Boolean](false)
}



class GridPlot extends Plot {
    object children extends Field[List[List[Plot]]]
    object border_space extends Field[Int](0)
}



abstract class GuideRenderer extends Renderer {
    object plot extends Field[Plot]
    object bounds extends Field[(Double, Double)] // TODO: Either[Auto, (Float, Float)]]

    object x_range_name extends Field[String]("default")
    object y_range_name extends Field[String]("default")
}

abstract class Axis extends GuideRenderer {
    object visible extends Field[Boolean](true)
    object location extends Field[Location]

    def defaultTicker: Ticker
    def defaultFormatter: TickFormatter

    object ticker extends Field[Ticker](defaultTicker)
    object formatter extends Field[TickFormatter](defaultFormatter)

    object axis_label extends Field[String]
    object axis_label_standoff extends Field[Int]
    axis_label = include[TextProps]

    object major_label_standoff extends Field[Int]
    object major_label_orientation extends Field[Orientation] // TODO: Either[Orientation, Double]
    major_label = include[TextProps]

    axis = include[LineProps]

    major_tick = include[LineProps]
    object major_tick_in extends Field[Int]
    object major_tick_out extends Field[Int]

    minor_tick = include[LineProps]
    object minor_tick_in extends Field[Int]
    object minor_tick_out extends Field[Int]
}

abstract class ContinuousAxis extends Axis

class LinearAxis extends ContinuousAxis {
    def defaultTicker: Ticker = new BasicTicker()
    def defaultFormatter: TickFormatter = new BasicTickFormatter()
}

class LogAxis extends ContinuousAxis {
    def defaultTicker: Ticker = new LogTicker().num_minor_ticks(10)
    def defaultFormatter: TickFormatter = new LogTickFormatter()
}

class CategoricalAxis extends Axis {
    def defaultTicker: Ticker = new CategoricalTicker()
    def defaultFormatter: TickFormatter = new CategoricalTickFormatter()
}

class DatetimeAxis extends LinearAxis {
    override def defaultTicker: Ticker = new DatetimeTicker()
    override def defaultFormatter: TickFormatter = new DatetimeTickFormatter()

    object scale extends Field[String]("time")
    object num_labels extends Field[Int](8)
    object char_width extends Field[Int](10)
    object fill_ratio extends Field[Double](0.3)
}

class Grid extends GuideRenderer {
    object dimension extends Field[Int](0)
    object ticker extends Field[Ticker]

    def axis(axis: Axis): SelfType = {
        axis.ticker.valueOpt.foreach(this.ticker := _)
        this
    }

    grid = include[LineProps]
}



abstract class MapOptions extends HasFields {
    object lat extends Field[Double]
    object lng extends Field[Double]
    object zoom extends Field[Int](12)
}

abstract class MapPlot extends Plot

class GMapOptions extends MapOptions {
    object map_type extends Field[MapType]
}

class GMapPlot extends MapPlot {
    object map_options extends Field[GMapOptions]
}

class GeoJSOptions extends MapOptions

class GeoJSPlot extends MapPlot {
    object map_options extends Field[GeoJSOptions]
}




abstract class ColorMapper extends PlotObject

class LinearColorMapper extends ColorMapper {
    object palette extends Field[Seq[Color]](Palette.Greys9)

    object low extends Field[Double]
    object high extends Field[Double]

    object reserve_color extends Field[Color](Color.Transparent)
    object reserve_val extends Field[Double]
}



sealed abstract class Marker extends Glyph with FillProps with LineProps {
    object x extends Spatial[Double]
    object y extends Spatial[Double]
    object size extends Spatial[Double](SpatialUnits.Screen) with NonNegative
}

class Asterisk extends Marker

class Circle extends Marker {
    object radius extends Spatial[Double](SpatialUnits.Data) with NonNegative
    object radius_dimension extends Field[Dimension]
}

class CircleCross extends Marker

class CircleX extends Marker

class Cross extends Marker

class Diamond extends Marker

class DiamondCross extends Marker

class InvertedTriangle extends Marker

class Square extends Marker {
    object angle extends Angular[Double]
}

class SquareCross extends Marker

class SquareX extends Marker

class Triangle extends Marker

class PlainX extends Marker {
    override val typeName = "X"
}



class PlotContext extends PlotObject {
    object children extends Field[List[Widget]]
}



trait ByReference { self: HasFields =>
    type RefType

    def getRef: RefType
    def id: AbstractField { type ValueType = String }
}

case class Ref(id: String, `type`: String)

abstract class PlotObject extends HasFields with ByReference {
    type RefType = Ref

    def getRef = Ref(id.value, typeName)
    object id extends Field[String](IdGenerator.next())
}




class Plot extends Widget {
    object title extends Field[String]("")

    title = include[TextProps]
    outline = include[LineProps]

    object x_range extends Field[Range]
    object y_range extends Field[Range]

    object extra_x_ranges extends Field[Map[String, Range]]
    object extra_y_ranges extends Field[Map[String, Range]]

    object x_mapper_type extends Field[String]("auto")
    object y_mapper_type extends Field[String]("auto")

    object renderers extends Field[List[Renderer]]
    object tools extends Field[List[Tool]] with ToolsField

    object tool_events extends Field[ToolEvents](new ToolEvents())

    object left extends Field[List[Renderer]]
    object right extends Field[List[Renderer]]
    object above extends Field[List[Renderer]]
    object below extends Field[List[Renderer]]

    object toolbar_location extends Field[Location](Location.Above)
    object logo extends Field[Logo](Logo.Normal)

    object plot_width extends Field[Int](600)
    object plot_height extends Field[Int](600)

    def width = plot_width
    def height = plot_height

    object background_fill extends Field[Color](Color.White)
    object border_fill extends Field[Color](Color.White)

    object min_border_top extends Field[Int]
    object min_border_bottom extends Field[Int]
    object min_border_left extends Field[Int]
    object min_border_right extends Field[Int]
    object min_border extends Field[Int]

    object h_symmetry extends Field[Boolean](true)
    object v_symmetry extends Field[Boolean](false)

    def addGlyph(glyph: Glyph): GlyphRenderer = {
        addGlyph(new ColumnDataSource(), glyph)
    }

    def addGlyph(source: DataSource, glyph: Glyph): GlyphRenderer = {
        val renderer = new GlyphRenderer().data_source(source).glyph(glyph)
        renderers <<= (_ :+ renderer)
        renderer
    }

    def addLayout(renderer: Renderer, layout: Layout): Renderer = {
        layout match {
            case Layout.Left   => left  <<= (renderer +: _)
            case Layout.Right  => right <<= (renderer +: _)
            case Layout.Above  => above <<= (renderer +: _)
            case Layout.Below  => below <<= (renderer +: _)
            case Layout.Center =>
        }
        renderers <<= (_ :+ renderer)
        renderer
    }
}



abstract class Range extends PlotObject

class Range1d extends Range {
    object start extends Field[Double]
    object end extends Field[Double]
}

abstract class DataRange extends Range {
    object sources extends Field[List[ColumnsRef]]
}

class DataRange1d extends DataRange {
    object rangepadding extends Field[Double](0.1)

    object start extends Field[Double]
    object end extends Field[Double]
}

class FactorRange extends Range {
    object factors extends Field[List[String]] // TODO: also List[Int]
}



abstract class Renderer extends PlotObject

class GlyphRenderer extends Renderer {
    // TODO: object server_data_source extends Field[ServerDataSource]
    object data_source extends Field[DataSource](new ColumnDataSource())

    object glyph extends Field[Glyph]
    object selection_glyph extends Field[Glyph]
    object nonselection_glyph extends Field[Glyph]

    object x_range_name extends Field[String]("default")
    object y_range_name extends Field[String]("default")
}

class Legend extends Renderer {
    object plot extends Field[Plot]

    object orientation extends Field[LegendOrientation]
    border = include[LineProps]

    object label_standoff extends Field[Int](15)
    object label_height extends Field[Int](20)
    object label_width extends Field[Int](50)
    label = include[TextProps]

    object glyph_height extends Field[Int](20)
    object glyph_width extends Field[Int](20)

    object legend_padding extends Field[Int](10)
    object legend_spacing extends Field[Int](3)

    object legends extends Field[List[(String, List[GlyphRenderer])]]
}

class BoxSelectionOverlay extends Renderer {
    override val typeName = "BoxSelection"

    object tool extends Field[BoxSelectTool]
}




import play.api.libs.json.Writes

class ColumnsRef extends HasFields {
    object source extends Field[DataSource]
    object columns extends Field[List[Symbol]]
}

abstract class DataSource extends PlotObject {
    object column_names extends Field[List[String]]
    object selected extends Field[List[Int]]

    def columns(columns: Symbol*): ColumnsRef =
        new ColumnsRef().source(this).columns(columns.toList)
}

class ColumnDataSource extends DataSource { source =>
    final override val typeName = "ColumnDataSource"

    object data extends Field[Map[Symbol, Any]]

    class Column[M[_]: ArrayLike, T](val name: Symbol, _value: M[T]) {
        this := _value

        def value: M[T] = source.data.value(name).asInstanceOf[M[T]]
        def :=(value: M[T]): Unit = source.addColumn(name, value)

        def ref: ColumnsRef = new ColumnsRef().source(source).columns(name :: Nil)
    }

    def column[M[_], T](value: M[T]): ColumnDataSource#Column[M, T] = macro ColumnMacro.columnImpl[M, T]

    def addColumn[M[_]: ArrayLike, T](name: Symbol, value: M[T]): SelfType = {
        data <<= (_ + (name -> value))
        this
    }
}

trait SourceImplicits {
    implicit def ColumnToColumnsRef[M[_]](column: ColumnDataSource#Column[M, _]): ColumnsRef = column.ref
}

private[bokeh] object ColumnMacro {
    import scala.reflect.macros.Context

    def columnImpl[M[_], T](c: Context)(value: c.Expr[M[T]])
            (implicit ev1: c.WeakTypeTag[M[_]], ev2: c.WeakTypeTag[T]): c.Expr[ColumnDataSource#Column[M, T]] = {
        import c.universe._

        val name = definingValName(c).map(name => c.Expr[String](Literal(Constant(name)))) getOrElse {
            c.abort(c.enclosingPosition, "column must be directly assigned to a val, such as `val x1 = column(List(1.0, 2.0, 3.0))`")
        }

        c.Expr[ColumnDataSource#Column[M, T]](q"new Column(Symbol($name), $value)")
    }

    def definingValName(c: Context): Option[String] = {
        import c.universe._

        c.enclosingClass.collect {
            case ValDef(_, name, _, rhs) if rhs.pos == c.macroApplication.pos => name.encoded
        }.headOption
    }
}

abstract class RemoteSource extends DataSource {
    object data_url extends Field[String]
    object polling_interval extends Field[Int]
}

class AjaxDataSource extends RemoteSource {
    object method extends Field[HTTPMethod](HTTPMethod.POST)
}




abstract class Ticker extends PlotObject {
    object num_minor_ticks extends Field[Int](5)
}

class AdaptiveTicker extends Ticker {
    object base extends Field[Double](10.0)
    object mantissas extends Field[List[Double]](List(2, 5, 10))
    object min_interval extends Field[Double](0.0)
    object max_interval extends Field[Double](100.0)
}

class CompositeTicker extends Ticker {
    object tickers extends Field[List[Ticker]]
}

class SingleIntervalTicker extends Ticker {
    object interval extends Field[Double]
}

class DaysTicker extends SingleIntervalTicker {
    object days extends Field[List[Int]]
}

class MonthsTicker extends SingleIntervalTicker {
    object months extends Field[List[Int]]
}

class YearsTicker extends SingleIntervalTicker

class BasicTicker extends Ticker

class LogTicker extends AdaptiveTicker

class CategoricalTicker extends Ticker

class DatetimeTicker extends Ticker

abstract class TickFormatter extends PlotObject

class BasicTickFormatter extends TickFormatter {
    // TODO: object precision extends Field[Either[Auto, Int]]
    object use_scientific extends Field[Boolean](true)
    object power_limit_high extends Field[Int](5)
    object power_limit_low extends Field[Int](-3)
}

class LogTickFormatter extends TickFormatter

class CategoricalTickFormatter extends TickFormatter

class DatetimeTickFormatter extends TickFormatter {
    object formats extends Field[Map[DatetimeUnits, List[String]]]
}

class NumeralTickFormatter extends TickFormatter {
    object format extends Field[String]("0,0")
    object language extends Field[NumeralLanguage]
    object rounding extends Field[RoundingFunction]
}

class PrintfTickFormatter extends TickFormatter {
    object format extends Field[String]("%s")
}




class ToolEvents extends PlotObject {
    object geometries extends Field[List[Map[Symbol, Any]]]
}

sealed abstract class Tool extends PlotObject {
    object plot extends Field[Plot]
}

class PanTool extends Tool {
    object dimensions extends Field[List[Dimension]](List(Dimension.Width, Dimension.Height))
}

class WheelZoomTool extends Tool {
    object dimensions extends Field[List[Dimension]](List(Dimension.Width, Dimension.Height))
}

class PreviewSaveTool extends Tool

class ResetTool extends Tool

class ResizeTool extends Tool

class CrosshairTool extends Tool

class BoxZoomTool extends Tool

abstract class TransientSelectTool extends Tool {
    object names extends Field[List[String]]
    object renderers extends Field[List[Renderer]]
}

abstract class SelectTool extends TransientSelectTool

class BoxSelectTool extends SelectTool {
    object select_every_mousemove extends Field[Boolean](true)
    object dimensions extends Field[List[Dimension]](List(Dimension.Width, Dimension.Height))
}

class LassoSelectTool extends SelectTool {
    object select_every_mousemove extends Field[Boolean](true)
}

class PolySelectTool extends SelectTool

class TapTool extends SelectTool {
    object action extends Field[Action]
    object always_active extends Field[Boolean](true)
}

class HoverTool extends TransientSelectTool {
    object tooltips extends Field[Tooltip]
    object always_active extends Field[Boolean](true)
    object snap_to_data extends Field[Boolean](true)
}



abstract class Widget extends PlotObject {
    object disabled extends Field[Boolean](false)
}
