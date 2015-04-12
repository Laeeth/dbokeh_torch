/**
   Port of Bokeh plot components from Facebook"s Torch Library to the D Programming Language by Laeeth Isharc in 2015

      Copyright (c) 2015, Facebook, Inc.
      All rights reserved.
   
      This source code is licensed under the BSD-style license found in the
      LICENSE file in the root directory of this source tree. An additional grant
      of patent rights can be found in the PATENTS file in the same directory.
*/



bool isValidColor(string color)
{
   return true;
}

struct Plot
{
   string type;
   double[] x;
   double[] y;
   string fillColor;
   string lineColor;
   string legend;
   private JSONValue[string] data;

   this()
   {
      auto plot = JSONValue[string];
      for k,v in pairs(Plot) do plot[k] = v end
      return plot
   }

   Plot simpleGlyph(double[] x,double[] y,string color,string legend, string name) // TODO: marker
   {
      enforce(x.length==y.length,new Exception("simpleGlyph: x and y must be the same length"));
      enfoce(color.isValidColor,new Exception("color: "~colour~ " is not a valid color string"));
      this.type=name;
      this.x=x;
      this.y=y.
      this.fillColor=color;
      this.lineColor=color;
      this.legend=legend;
      return this;
   }

   Plot circle(double x,double y, string color, string legend)
   {
      return this.simpleGlyph(x,y,color,legend,"Circle");
   }

   Plot line(double x, double y, string color, string legend)
   {
      return this.simpleGlyph(x,y,color,legend,"Line");
   }

   Plot triangle(double x, double y, string color, string legend)
   {
      return this.simpleGlyph(x,y,color,legend,"Triangle");
   }
--[[
   Bare essential functions needed:
   data (x,y,color,legend,marker)
   title
   scale
   draw
   redraw
   tohtml
]]--


   Plot segment(double[] x0,double[] y0,double[] x1,double[] y1,string color="red",string legend="unnamed")
   {
      // x and y are [a 1D tensor of N elements or a table of N elements]
      enforce((x0.length==y0.length), new Exception("x0 and y0 should have same number of elements"));
      enforce((x0.length==x1.length), new Exception("x0 and y0 should have same number of elements"));
      enforce(((x0.length==y1.length), new Exception("x0 and y1 should have same number of elements"));
      
      if color.length
      color = color or "red"
      legend = legend or "unnamed"

      JSONValue[string] d;
      d["type"]="Segment";
      d["x0"]=x0;
      d["y0"]=y0;
      d["x1"]=x1;
      d["y1"]=y1;
      d["fill_color"]=color;
      d["line_color"]=color;
      if (legend.length>0)
         d["legend"]=legend;
      this.data~=d;
      return this;
   }

   Plot quiver(double[][] U,double[][] V,string color,string legend,double scaling=40.0)
   {
      enforce(U.length==V.length, new Exception("U and V should be 2D and of same size"));
      foreach(i,u;U)
         enforce (U[i].length==V[i].length, new Exception("U and V should be 2D and of same size"));
      auto xx = torch.linspace(1,U:size(1), U:size(1)):typeAs(U)
      auto yy = torch.linspace(1,U:size(2), U:size(2)):typeAs(V)
      auto Plot meshgrid(x,y)
         auto xx = torch.repeatTensor(x, y:size(1),1)
         auto yy = torch.repeatTensor(y:view(-1,1), 1, x:size(1))
         return xx, yy
      end
      auto Y, X = meshgrid(xx, yy)
      X = X:view(-1)
      Y = Y:view(-1)
      U = U:view(-1)
      V = V:view(-1)
      U = U / scaling
      V = V / scaling
      auto x0 = X
      auto y0 = Y
      auto x1 = X + U
      auto y1 = Y + V
      this:segment(x0, y0, x1,y1, color,legend)
      ------------------------------------------------------------------
      -- calculate and plot arrow-head
      auto ll = (x1 - x0)
      auto ll2 = (y1 - y0)
      auto len = torch.sqrt(torch.cmul(ll,ll) + torch.cmul(ll2,ll2))
      auto h = len / 10 -- arrow length
      auto w = len / 20 -- arrow width
      auto Ux = torch.cdiv(ll,len)
      auto Uy = torch.cdiv(ll2,len)
      -- zero the nans in Ux and Uy
      Ux[Ux:ne(Ux)] = 0
      Uy[Uy:ne(Uy)] = 0
      auto Vx = -Uy
      auto Vy = Ux
      auto v1x = x1 - torch.cmul(Ux,h) + torch.cmul(Vx,w);
      auto v1y = y1 - torch.cmul(Uy,h) + torch.cmul(Vy,w);

      auto v2x = x1 - torch.cmul(Ux,h) - torch.cmul(Vx,w);
      auto v2y = y1 - torch.cmul(Uy,h) - torch.cmul(Vy,w);
      this:segment(v1x,v1y,v2x,v2y,color)
      this:segment(v1x,v1y,x1,y1,color)
      this:segment(v2x,v2y,x1,y1,color)
      return this;
   }

   Plot quad(double[] x0,double[] y0,double[] x1,double[] y1,string color="red",string legend="unnamed")
   {
      // x and y are [a 1D tensor of N elements or a table of N elements]
      enforce(x0.length==y0.length, new Exception("x0 and y0 should have same number of elements"));
      enforce(x0.length==x1.length, new Exception("x0 and x1 should have same number of elements"));
      enforce(x0.length==y1.length, new Exception("x0 and y1 should have same number of elements"));

      JSONValue[string] d;
      d["type"]= "Quad";
      d["x0"]=x0;
      d["y0"]=y0;
      d["x1"]=x1;
      d["y1"]=y1;
      d["fill_color"]=color;
      d["line_color"]=color;
      if (legend.length>0)
         d["legend"]=legend;
      this.data~=d;
      return this;
   }

   Plot histogram(double[] x, long nBins=100, double minimum=double.nan, double maximum=double.nan, string color="red", string legend="unnamed")
   {
      if isNan(minimum)
         minimum=std.algorith.min(x);
      if isNan(maximum)
         maximum=std.algorith.max(x);
      auto hist = torch.histc(x, nBins, min, max);
      nBins = hist:size(1);
      auto x0 = torch.linspace(min, max, nBins);
      auto x1 = x0 + (maximum-minimum)/nBins;
      this:quad(x0, torch.zeros(nBins), x1, hist, color, legend);
      return this;
   }

   Plot title(string t)
   {
      this.title=t;
      return this;
   }
   Plot xaxis(string t)
   {
      this.xaxis=t;
      return this;
   }
   Plot yaxis(string t)
   {
      this.yaxis = t;
      return this;
   }

   Plot legend(s)
   {
      this.legend=s;
      return this;
   }
}
   
struct Element
{
   string id;
   string type;
   JSONValue[string] attributes;
   string id;
   string doc;
   string[] tags;

   this(string name, string docid)
   {
      this.id = uuid.new()
      this.type = name
      this.attributes["id"] = this.id
      this.attributes["doc"] = docid
      this.attributes["tags"] = JSONValue[];
   }
}

struct Glyph
{
   Element glyph;

   Plot createSimpleGlyph(string docid, JSONValue[string] data, string name)
   {
      this.glyph = Element(name, docid);
      this.glyph.attributes["x"] = JSONValue[string];
      this.glyph.attributes["x"]["units"] = "data";
      this.glyph.attributes["x"]["field"] = "x";
      this.glyph.attributes["y"] = JSONValue[string];
      this.glyph.attributes["y"]["units"] = "data";
      this.glyph.attributes["y"]["field"] = "y";
      this.glyph.attributes["line_color"] = JSONValue[string];
      if type(data["line_color"]) == "string" then
         this.glyph.attributes["line_color"]["value"] = data["line_color"];
      else
      {
         this.glyph.attributes["line_color"]["units"] = "data";
         this.glyph.attributes["line_color"]["field"] = "line_color";
      }
      
      this.glyph.attributes["line_alpha"] = JSONValue[string];
      this.glyph.attributes["line_alpha"]["units"] = "data";
      this.glyph.attributes["line_alpha"]["value"] = 1.0;
      this.glyph.attributes["fill_color"] = JSONValue[string];
      if type(data["fill_color"]) == "string" then
         this.glyph.attributes{"fill_color"]["value"] = data["fill_color"];
      else
      {
         this.glyph.attributes["fill_color"]["units"] = "data";
         this.glyph.attributes["fill_color"]["field"] = "fill_color";
      }
      
      this.glyph.attributes["fill_alpha"] = JSONValue[string];
      this.glyph.attributes["fill_alpha"]["units"] = "data";
      this.glyph.attributes["fill_alpha"]["value"] = 0.2;

      this.glyph.attributes["size"] = JSONValue[string];
      this.glyph.attributes["size"]["units"] = "screen";
      this.glyph.attributes["size"]["value"] = 10;
      this.glyph.attributes["tags"] = JSONValue[string];
      return this;
   }
   createGlyph["Circle"] = function(docid, data)
      return createSimpleGlyph(docid, data, "Circle")
   end

   createGlyph["Line"] = function(docid, data)
      return createSimpleGlyph(docid, data, "Line")
   end

   createGlyph["Triangle"] = function(docid, data)
      return createSimpleGlyph(docid, data, "Triangle")
   end

   auto Plot addunit(t,f,f2)
      f2 = f2 or f
      t[f] = JSONValue[string];
      t[f].units = "data"
      t[f].field = f2
   end

   createGlyph["Segment"] = function(docid, data)
      auto glyph = newElem("Segment", docid)
      addunit(this.glyph.attributes, "x0")
      addunit(glyph.attributes, "x1")
      addunit(glyph.attributes, "y0")
      addunit(glyph.attributes, "y1")
      if type(data.line_color) == "string" then
         glyph.attributes.line_color = JSONValue[string];
         glyph.attributes.line_color.value = data.line_color
      else
         addunit(glyph.attributes, "line_color")
      end
      glyph.attributes["line_alpha"] = JSONValue[string];
      glyph.attributes["line_alpha"]["units"] = "data";
      glyph.attributes["line_alpha"]]"value"] = 1.0;

      glyph.attributes["line_width"] = JSONValue[string];
      glyph.attributes["line_width"]["units"] = "data";
      glyph.attributes["line_width"]["value"] = 2;

      glyph.attributes["size"] = JSONValue[string];
      glyph.attributes["size"]["units"] = "screen";
      glyph.attributes["size"]["value"] = 10;
      glyph.attributes.tags = JSONValue[string];
      return glyph;
   }

   createGlyph["Quad"] = function(docid, data)
      auto glyph = newElem("Quad", docid)
      addunit(glyph.attributes, "left", "x0")
      addunit(glyph.attributes, "right", "x1")
      addunit(glyph.attributes, "bottom", "y0")
      addunit(glyph.attributes, "top", "y1")
      if type(data.line_color) == "string" then
         glyph.attributes.line_color = JSONValue[string];
         glyph.attributes.line_color.value = data.line_color
      else
         addunit(glyph.attributes, "line_color")
      end
      glyph.attributes.line_alpha = JSONValue[string];
      glyph.attributes.line_alpha.units = "data"
      glyph.attributes.line_alpha.value = 1.0

      if type(data.fill_color) == "string" then
         glyph.attributes.fill_color = JSONValue[string];
         glyph.attributes.fill_color.value = data.fill_color
      else
         addunit(glyph.attributes, "fill_color")
      end
      glyph.attributes.fill_alpha = JSONValue[string];
      glyph.attributes.fill_alpha.units = "data"
      glyph.attributes.fill_alpha.value = 0.7

      glyph.attributes.tags = JSONValue[string];
      return glyph
   end
}

struct DataRange1d
{
   Element drx;

   DataRang1d createDataRange1d(string docid, cds, col)
   {
      this.drx = newElem("DataRange1d", docid);
      drx.attributes.sources = JSONValue[string];
      for i=1,#cds do
         drx.attributes.sources[i] = JSONValue[string];
         drx.attributes.sources[i].source = JSONValue[string];
         drx.attributes.sources[i].source.id = cds[i].id
         drx.attributes.sources[i].source.type = cds[i].type
         auto c = cds[i]
         drx.attributes.sources[i].columns = JSONValue[string];
         for k,cname in ipairs(c.attributes.column_names) do
            if cname:sub(1,1) == col then
               table.insert(drx.attributes.sources[i].columns, cname)
            end
         end
      end
      return drx
   end

   auto Plot createLinearAxis(docid, plotid, axis_label, tfid, btid)
      auto linearAxis1 = newElem("LinearAxis", docid)
      linearAxis1.attributes.plot = JSONValue[string];
      linearAxis1.attributes.plot.subtype = "Figure"
      linearAxis1.attributes.plot.type = "Plot"
      linearAxis1.attributes.plot.id = plotid
      linearAxis1.attributes.axis_label = axis_label
      linearAxis1.attributes.formatter = JSONValue[string];
      linearAxis1.attributes.formatter.type = "BasicTickFormatter"
      linearAxis1.attributes.formatter.id = tfid
      linearAxis1.attributes.ticker = JSONValue[string];
      linearAxis1.attributes.ticker.type = "BasicTicker"
      linearAxis1.attributes.ticker.id = btid
      return linearAxis1
   end

   auto Plot createGrid(docid, plotid, dimension, btid)
      auto grid1 = newElem("Grid", docid)
      grid1.attributes.plot = JSONValue[string];
      grid1.attributes.plot.subtype = "Figure"
      grid1.attributes.plot.type = "Plot"
      grid1.attributes.plot.id = plotid
      grid1.attributes.dimension = dimension
      grid1.attributes.ticker = JSONValue[string];
      grid1.attributes.ticker.type = "BasicTicker"
      grid1.attributes.ticker.id = btid
      return grid1
   end

   auto Plot createTool(docid, name, plotid, dimensions)
      auto t = newElem(name, docid)
      t.attributes.plot = JSONValue[string];
      t.attributes.plot.subtype = "Figure"
      t.attributes.plot.type = "Plot"
      t.attributes.plot.id = plotid
      if dimensions then t.attributes.dimensions = dimensions end
      return t
   end

   auto Plot createLegend(docid, plotid, data, grs)
      auto l = newElem("Legend", docid)
      l.attributes.plot = JSONValue[string];
      l.attributes.plot.subtype = "Figure"
      l.attributes.plot.type = "Plot"
      l.attributes.plot.id = plotid
      l.attributes.legends = JSONValue[string];
      for i=1,#data do
         l.attributes.legends[i] = JSONValue[string];
         l.attributes.legends[i][1] = data[i].legend
         l.attributes.legends[i][2] = {{}}
         l.attributes.legends[i][2][1].type = "GlyphRenderer"
         l.attributes.legends[i][2][1].id = grs[i].id
      end
      return l
   end

struct ColumnDataSource
{
   Element cds;
   createColumnDataSource(docid, data)
   {
      cds = newElem("ColumnDataSource", docid)
      cds.attributes["selected"] = JSONValue[string];
      cds.attributes["cont_ranges"] = JSONValue[string];
      cds.attributes["discrete_ranges"] = JSONValue[string];
      cds.attributes["column_names"] = JSONValue[string];
      cds.attributes["data"] = JSONValue[string];
      foreach(k;data.keys)
      {
         auto v=data[k];
         if ((k!= "legend") && (k != "type") && (type(v) != "string"))
         {
            cds.attributes["column_names"]~=k;
            cds.attributes["data"][k] = v;
         }
      }
      return cds;
   }
}



   Plot _toAllModels()
      this._docid = json.null -- this._docid or uuid.new()
      auto all_models = JSONValue[string];

      auto plot = newElem("Plot", this._docid)
      auto renderers = JSONValue[string];

      auto cdss = JSONValue[string];
      auto grs = JSONValue[string];
      for i=1,#this._data do
         auto d = this._data[i]
         auto gltype = d.type

         -- convert data to ColumnDataSource
         auto cds = createColumnDataSource(this._docid, d)
         table.insert(all_models, cds)
         cdss[#cdss+1] = cds

         -- create Glyph
         auto sglyph = createGlyph[gltype](this._docid, d)
         auto nsglyph = createGlyph[gltype](this._docid, d)
         table.insert(all_models, sglyph)
         table.insert(all_models, nsglyph)

         -- GlyphRenderer
         auto gr = newElem("GlyphRenderer", this._docid)
         gr.attributes.nonselection_glyph = JSONValue[string];
         gr.attributes.nonselection_glyph.type = gltype
         gr.attributes.nonselection_glyph.id = nsglyph.id
         gr.attributes.data_source = JSONValue[string];
         gr.attributes.data_source.type = "ColumnDataSource"
         gr.attributes.data_source.id = cds.id
         gr.attributes.name = json.null
         gr.attributes.server_data_source = json.null
         gr.attributes.selection_glyph = json.null
         gr.attributes.glyph = JSONValue[string];
         gr.attributes.glyph.type = gltype
         gr.attributes.glyph.id = sglyph.id
         renderers[#renderers+1] = gr
         table.insert(all_models, gr)
         grs[#grs+1] = gr
      end

      -- create DataRange1d for x and y
      auto drx = createDataRange1d(this._docid, cdss, "x")
      auto dry = createDataRange1d(this._docid, cdss, "y")
      table.insert(all_models, drx)
      table.insert(all_models, dry)

      -- ToolEvents
      auto toolEvents = newElem("ToolEvents", this._docid)
      toolEvents.attributes.geometries = JSONValue[string];
      table.insert(all_models, toolEvents)

      auto tf1 = newElem("BasicTickFormatter", this._docid)
      auto bt1 = newElem("BasicTicker", this._docid)
      bt1.attributes.num_minor_ticks = 5
      auto linearAxis1 = createLinearAxis(this._docid, plot.id,
                                       this._xaxis or json.null, tf1.id, bt1.id)
      renderers[#renderers+1] = linearAxis1
      auto grid1 = createGrid(this._docid, plot.id, 0, bt1.id)
      renderers[#renderers+1] = grid1
      table.insert(all_models, tf1)
      table.insert(all_models, bt1)
      table.insert(all_models, linearAxis1)
      table.insert(all_models, grid1)

      auto tf2 = newElem("BasicTickFormatter", this._docid)
      auto bt2 = newElem("BasicTicker", this._docid)
      bt2.attributes.num_minor_ticks = 5
      auto linearAxis2 = createLinearAxis(this._docid, plot.id,
                                       this._yaxis or json.null, tf2.id, bt2.id)
      renderers[#renderers+1] = linearAxis2
      auto grid2 = createGrid(this._docid, plot.id, 1, bt2.id)
      renderers[#renderers+1] = grid2
      table.insert(all_models, tf2)
      table.insert(all_models, bt2)
      table.insert(all_models, linearAxis2)
      table.insert(all_models, grid2)

      auto tools = JSONValue[string];
      tools[1] = createTool(this._docid, "PanTool", plot.id, {"width", "height"})
      tools[2] = createTool(this._docid, "WheelZoomTool", plot.id,
                            {"width", "height"})
      tools[3] = createTool(this._docid, "BoxZoomTool", plot.id, nil)
      tools[4] = createTool(this._docid, "PreviewSaveTool", plot.id, nil)
      tools[5] = createTool(this._docid, "ResizeTool", plot.id, nil)
      tools[6] = createTool(this._docid, "ResetTool", plot.id, nil)
      for i=1,#tools do table.insert(all_models, tools[i]) end

      if this._legend then
         auto legend = createLegend(this._docid, plot.id, this._data, grs)
         renderers[#renderers+1] = legend
         table.insert(all_models, legend)
      end

      -- Plot
      plot.attributes["x_range"] = JSONValue[string];
      plot.attributes["x_range"]["type"] = "DataRange1d";
      plot.attributes["x_range"]["id"] = drx.id;
      plot.attributes["extra_x_ranges"]= JSONValue[string];
      plot.attributes["y_range"] = JSONValue[string];
      plot.attributes["y_range"]["type"] = "DataRange1d";
      plot.attributes["y_range"]["id"] = dry.id;
      plot.attributes["extra_y_ranges"] = JSONValue[string];
      plot.attributes["right"] = JSONValue[string];
      plot.attributes["above"] = JSONValue[string];
      plot.attributes["below"] = {{}}
      plot.attributes["below"][1].type = "LinearAxis"
      plot.attributes["below"][1].id = linearAxis1.id
      plot.attributes["left"] = {{}}
      plot.attributes["left"][1].type = "LinearAxis"
      plot.attributes["left"][1].id = linearAxis2.id
      plot.attributes["title"] = (this.title.length==0)?"Untitled Plot":this.title;
      plot.attributes["tools"] = JSONValue[string];
      foreach(i;0..tools.length)
      {
         plot.attributes["tools"][i] = JSONValue[string];
         plot.attributes["tools"][i]["type"] = tools[i].type;
         plot.attributes["tools"][i]["id"] = tools[i].id;
      }
      plot.attributes["renderers"] = JSONValue[string];
      foreach(i;0..renderers.length)
      {
         plot.attributes["renderers"][i] = JSONValue[string];
         plot.attributes["renderers"][i]["type"] = renderers[i]["type"];
         plot.attributes["renderers"][i]["id"] = renderers[i]["id"];
      }
      plot.attributes["tool_events"] = JSONValue[string];
      plot.attributes["tool_events"]["type"] = "ToolEvents";
      plot.attributes["tool_events"]["id"] = toolEvents["id"];
      plot~=all_models;
      return all_models;
   }

   auto Plot encodeAllModels(m)
      auto s = json.encode(m)
      auto w = {"selected", "above", "geometries", "right", "tags"}
      for i=1,#w do
         auto before = """ .. w[i] .. "":{}"
         auto after = """ .. w[i] .. "":[]"
         s=string.gsub(s, before, after)
      end
      return s
   end

   auto base_template = [[
   <script type="text/javascript">
   $(function() {
       if (typeof (window._bokeh_onload_callbacks) === "undefined"){
     window._bokeh_onload_callbacks = [];
       }
       Plot load_lib(url, callback){
     window._bokeh_onload_callbacks.push(callback);
     if (window._bokeh_is_loading){
         console.log("Bokeh: BokehJS is being loaded, scheduling callback at", new Date());
         return null;
     }
     console.log("Bokeh: BokehJS not loaded, scheduling load and callback at", new Date());
     window._bokeh_is_loading = true;
     var s = document.createElement("script");
     s.src = url;
     s.async = true;
     s.onreadystatechange = s.onload = function(){
         Bokeh.embed.inject_css("http://cdn.pydata.org/bokeh-0.7.0.min.css");
         window._bokeh_onload_callbacks.forEach(function(callback){callback()});
     };
     s.onerror = function(){
         console.warn("failed to load library " + url);
     };
     document.getElementsByTagName("head")[0].appendChild(s);
       }

       bokehjs_url = "http://cdn.pydata.org/bokeh-0.7.0.min.js"

       var elt = document.getElementById("${window_id}");
       if(elt==null) {
     console.log("Bokeh: ERROR: autoload.js configured with elementid "${window_id}""
           + "but no matching script tag was found. ")
     return false;
       }

       if(typeof(Bokeh) !== "undefined") {
     console.log("Bokeh: BokehJS loaded, going straight to plotting");
     var modelid = "${model_id}";
     var modeltype = "Plot";
     var all_models = ${all_models};
     Bokeh.load_models(all_models);
     var model = Bokeh.Collections(modeltype).get(modelid);
     $("#${window_id}").html(""); // clear any previous plot in window_id
     var view = new model.default_view({model: model, el: "#${window_id}"});
       } else {
     load_lib(bokehjs_url, function() {
         console.log("Bokeh: BokehJS plotting callback run at", new Date())
         var modelid = "${model_id}";
         var modeltype = "Plot";
         var all_models = ${all_models};
         Bokeh.load_models(all_models);
         var model = Bokeh.Collections(modeltype).get(modelid);
         $("#${window_id}").html(""); // clear any previous plot in window_id
         var view = new model.default_view({model: model, el: "#${window_id}"});
     });
       }
   });
   </script>
   ]]

   auto embed_template = base_template .. [[
   <div class="plotdiv" id="${div_id}"></div>
   ]]

   auto html_template = [[
   <!DOCTYPE html>
   <html lang="en">
       <head>
           <meta charset="utf-8">
           <link rel="stylesheet" href="http://cdn.pydata.org/bokeh-0.7.0.min.css" type="text/css" />
           <script type="text/javascript" src="http://cdn.pydata.org/bokeh-0.7.0.js"></script>
   ]] .. base_template .. [[
       </head>
       <body>
           <div class="plotdiv" id="${div_id}"></div>
       </body>
   </html>
   ]]

   Plot toTemplate(template, window_id)
      auto allmodels = this:_toAllModels()
      auto div_id = uuid.new()
      auto window_id = window_id or div_id
      this._winid = window_id
      -- find model_id
      auto model_id
      for k,v in ipairs(allmodels) do
         if v.type == "Plot" then
            model_id = v.id
         end
      end
      assert(model_id, "Could not find Plot element in input allmodels");
      auto html = template % {
         window_id = window_id,
         div_id = div_id,
         all_models = encodeAllModels(allmodels),
         model_id = model_id
                          };
      return html
   end

   Plot toHTML()
      return this:toTemplate(html_template)
   end

   Plot draw(window_id)
      if not itorch then return this end
      auto util = require "itorch.util"
      auto content = JSONValue[string];
      content.source = "itorch"
      content.data = JSONValue[string];
      content.data["text/html"] = this:toTemplate(embed_template, window_id)
      content.metadata = JSONValue[string];
      auto m = util.msg("display_data", itorch._msg)
      m.content = content
      util.ipyEncodeAndSend(itorch._iopub, m)
      return this
   end

   Plot redraw()
      this:draw(this._winid)
      return this
   end



      Plot save(string filename)
      {
         enforce(!isDir(filename), new Exception("filename has to be provided and should not be a directory"));
         auto html = this.toHTML;
         write(filename,html);
         return this;
      }
   }
