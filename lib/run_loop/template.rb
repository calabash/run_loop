require 'erb'

module RunLoop

  # class to break up javascript templates in to reusable chunks
  class UIAScriptTemplate < ERB
    def initialize(template_root, template_relative_path)
      @template_root = template_root
      @template = File.read(File.join(@template_root, template_relative_path))
      super(@template)
    end

    def render_template(template_relative_path)
      return UIAScriptTemplate.new(@template_root, template_relative_path).result
    end

    def result
      super(binding)
    end
  end

end
