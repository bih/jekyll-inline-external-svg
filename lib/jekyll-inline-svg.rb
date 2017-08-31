require "nokogiri"
require 'svg_optimizer'
require 'jekyll/liquid_extensions'

PLUGINS_BLACKLIST = [
  SvgOptimizer::Plugins::CleanupId,
]

PLUGINS = SvgOptimizer::DEFAULT_PLUGINS.delete_if {|plugin|
  PLUGINS_BLACKLIST.include? plugin
}


module Jekyll
  module Tags
    class JekyllInlineSvg < Liquid::Tag
      #import lookup_variable function
      # https://github.com/jekyll/jekyll/blob/master/lib/jekyll/liquid_extensions.rb
      include Jekyll::LiquidExtensions

      # For interpoaltion, look for liquid variables
      VARIABLE = /\{\{\s*([\w]+\.?[\w]*)\s*\}\}/i

      #Separate file path from other attributes
      PATH_SYNTAX = %r!
        ^(?<path>[^\s"']+|"[^"]*"|'[^']*')
        (?<params>.*)
      !x
      PARAM_SYNTAX= %r!
        ([\w-]+)\s*=\s*
        (?:"([^"\\]*(?:\\.[^"\\]*)*)"|'([^'\\]*(?:\\.[^'\\]*)*)'|([\w\.-]+))
      !x

      def initialize(tag_name, input, tokens)
        super
        @svg, @params = JekyllInlineSvg.parse_params(input)
      end

      #lookup Liquid variables from markup in context
      def interpolate(markup, context)
        markup.scan VARIABLE do |variable|
          markup = markup.sub(VARIABLE, lookup_variable(context, variable.first))
        end
        markup
      end
      def split_params(markup, context)
        params={}
        while (match = PARAM_SYNTAX.match(markup))
          markup = markup[match.end(0)..-1]
          value = if match[2]
            interpolate(match[2].gsub(%r!\\"!, '"'), context)
          elsif match[3]
            interpolate(match[3].gsub(%r!\\'!, "'"),context)
          elsif match[4]
            lookup_variable(context, match[4])
          end
          params[match[1]] = value
        end
        return params
      end
      #Parse parameters. Returns : [svg_path, parameters]
      # Does not interpret variables as it's done at render time
      def self.parse_params(input)
        matched = input.strip.match(PATH_SYNTAX)
        path = matched["path"].gsub("\"","").gsub("'","").strip
        markup = matched["params"].strip
        return path, markup
      end
      def fmt(params)
        r = params.to_a.select{|v| v[1] != ""}.map {|v| %!#{v[0]}="#{v[1]}"!}
        r.join(" ")
      end
      def create_plugin(params)
        mod = Class.new(SvgOptimizer::Plugins::Base) do
          def self.set (p)
            @@params = p
          end
          def process
            @@params.each {|key,val| xml.root.set_attribute(key,val)}
            return xml
          end
        end
        mod.set(params)
        return mod
      end
      def render(context)
        #global site variable
        site = context.registers[:site]
        #check if given name is a variable. Otherwise use it as a file name
        svg_file = Jekyll.sanitized_path(site.source, interpolate(@svg,context))
        #replace variables with their current value
        params = split_params(@params,context)
        #because ie11 require to have a height AND a width
        if params.key? "width" and ! params.key? "height"
          params["height"] = params["width"]
        end
        #params = @params
        file = File.open(svg_file, "rb").read
        conf = lookup_variable(context,"site.svg")
        if conf["optimize"] == true
          xml = SvgOptimizer.optimize(file, [create_plugin(params)] + PLUGINS)
        else
          xml = Nokogiri::XML(file)
          params.each {|key,val| xml.root.set_attribute(key,val)}
          xml = xml.to_xml
        end
  	    return xml
      end
    end
  end
end
Liquid::Template.register_tag('svg', Jekyll::Tags::JekyllInlineSvg)
