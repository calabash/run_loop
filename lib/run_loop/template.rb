require 'erb'

module RunLoop

  # @!visibility private
  # Class to break up javascript templates in to reusable chunks
  class UIAScriptTemplate < ERB

    # @!visibility private
    def initialize(template_root, template_relative_path)
      @template_root = template_root
      @template = File.read(File.join(@template_root, template_relative_path)).force_encoding("utf-8")
      super(@template)
    end

    # @!visibility private
    def render_template(template_relative_path)
      return UIAScriptTemplate.new(@template_root, template_relative_path).result
    end

    # @!visibility private
    def result
      super(binding)
    end
  end
end
