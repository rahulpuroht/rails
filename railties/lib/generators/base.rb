require 'generators/actions'

module Rails
  module Generators
    class Error < Thor::Error
    end

    class Base < Thor::Group
      include Rails::Generators::Actions
      include Thor::Actions

      # Automatically sets the source root based on the class name.
      #
      def self.source_root
        @source_root ||= File.expand_path(File.join(File.dirname(__FILE__), base_name, generator_name, 'templates'))
      end

      # Convenience method to get the namespace from the class name. It's the
      # same as Thor default except that the Generator at the end of the class
      # is removed.
      #
      def self.namespace(name=nil) #:nodoc:
        if name
          super
        else
          @namespace ||= "#{base_name}:generators:#{generator_name}"
        end
      end

      protected

        # Use Rails default banner.
        #
        def self.banner
          "#{$0} #{generator_name} #{self.arguments.map(&:usage).join(' ')} [options]"
        end

        # Sets the base_name taking into account the current class namespace.
        #
        def self.base_name #:nodoc:
          @base_name ||= self.name.split('::').first.underscore
        end

        # Removes the namespaces and get the generator name. For example,
        # Rails::Generators::MetalGenerator will return "metal" as generator name.
        #
        def self.generator_name
          @generator_name ||= begin
            klass_name = self.name.split('::').last
            klass_name.gsub!(/Generator$/, '')
            klass_name.underscore
          end
        end

        # Small macro to add ruby as an option to the generator with proper
        # default value plus an instance helper method called shebang.
        #
        def self.add_shebang_option!
          require 'rbconfig'
          default = File.join(Config::CONFIG['bindir'], Config::CONFIG['ruby_install_name'])

          class_option :ruby, :type => :string, :aliases => "-r", :default => default,
                              :desc => "Path to the Ruby binary of your choice", :banner => "PATH"

          no_tasks do
            define_method :shebang do
              "#!#{options[:ruby] || "/usr/bin/env ruby"}"
            end
          end
        end

        # Small macro to add test_framework option and invoke it.
        #
        def self.add_and_invoke_test_framework_option!
          class_option :test_framework, :type => :string, :aliases => "-t", :default => "test_unit",
                                        :desc => "Test framework to be invoked by this generator", :banner => "NAME"

          define_method :invoke_test_framework do
            return unless options[:test_framework]
            name = "#{options[:test_framework]}:generators:#{self.class.generator_name}"

            begin
              invoke name
            rescue Thor::UndefinedTaskError
              say "Could not find and invoke '#{name}'."
            end
          end
        end
    end
  end
end
