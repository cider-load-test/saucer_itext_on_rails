
class String

  #include_class javax.xml.parsers.DocumentBuilder;
  include_class javax.xml.parsers.DocumentBuilderFactory;
  #include_class org.w3c.dom.Document;
  include_class org.xhtmlrenderer.pdf.ITextRenderer;
  include_class java.io.StringBufferInputStream
  include_class java.io.ByteArrayOutputStream

  def render_flying_saucer_pdf
    renderer = ITextRenderer.new
    renderer.set_document(DocumentBuilderFactory.new_instance.new_document_builder.parse(StringBufferInputStream.new(self)), nil)
    renderer.layout
    out = ByteArrayOutputStream.new
    
    renderer.createPDF(out)
    out.flush
    out.close
    String.from_java_bytes(out.to_byte_array)
  end
end

module FlyingSaucer
  module IText

    class Filter

      include_class javax.xml.parsers.DocumentBuilderFactory;
      include_class org.xhtmlrenderer.pdf.ITextRenderer;
      include_class java.io.StringBufferInputStream
      include_class java.io.ByteArrayOutputStream

      def self.filter(controller)
        return unless controller.params[:format] == "pdf"
        begin
          uri = URI.parse(controller.request.env['REQUEST_URI'])
          controller.response.body = create_pdf(controller.response.body,"#{uri.scheme}://#{uri.host}:#{uri.port}#{File.dirname(uri.path)}") 
        rescue
          controller.logger.warn "could not render pdf with body #{controller.response.body}"
          raise
        end
      end

      def self.create_pdf(str, url = nil)
        renderer = ITextRenderer.new
        renderer.set_document(DocumentBuilderFactory.new_instance.new_document_builder.parse(StringBufferInputStream.new(str)), url)
        renderer.layout
        out = ByteArrayOutputStream.new
        renderer.createPDF(out)
        out.flush
        out.close
        String.from_java_bytes(out.to_byte_array)
      end
    end
    
    module InstanceMethods
      def compile(template)
        "capture { #{super(template)} }.render_flying_saucer_pdf"
      end
    end

    class ERBPlugin < ActionView::TemplateHandlers::ERB
      include InstanceMethods
    end

    class BuilderPlugin < ActionView::TemplateHandlers::Builder
      include InstanceMethods
    end

  end
end

[[:itext_erb, FlyingSaucer::IText::ERBPlugin], 
 [:itext_builder, FlyingSaucer::IText::BuilderPlugin]].each do |args|

  if defined? ActionView::Template and ActionView::Template.respond_to? :register_template_handler
    ActionView::Template
  else
    ActionView::Base
  end.register_template_handler(*args)

end
