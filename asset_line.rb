class AssetLine
  def initialize(options)
    env = options.fetch(:env) { ENV['RACK_ENV'] }
    assets_root = options.fetch(:root)

    @compilers = [
      CSS.new(env, assets_root),
      JS.new(env, assets_root),
      Stylus.new(env, assets_root),
      CoffeeScript.new(env, assets_root),
      ES6.new(env, assets_root),
      NullCompiler.new
    ]
  end

  def fetch(filename)
    @compilers
      .find { |compiler| compiler.can_handle?(filename) }
      .compile(filename)
  end

  UnhandableAsset = Class.new(StandardError)

  private

  class SimpleAsset
    def initialize(env, root, type:, ext:)
      @env = env
      @root = File.join root, type
      @ext = ext
    end

    def can_handle?(filename, real_ext: nil)
      !!filename.match(/\.#{real_ext || @ext}$/i) &&
        File.exist?(file_path(filename))
    end

    def compile(filename)
      File.read(file_path(filename))
    end

    private

    def file_path(filename)
      File.join(@root, filename.gsub(/(?<=\.).+$/, @ext))
    end
  end

  class CSS < SimpleAsset
    def initialize(env, root)
      super(env, root, type: 'stylesheets', ext: 'css')
    end
  end

  class JS < SimpleAsset
    def initialize(env, root)
      super(env, root, type: 'javascripts', ext: 'js')
    end
  end

  class Stylus < SimpleAsset
    require 'stylus'

    EXT = 'styl'.freeze

    def initialize(env, root)
      super(env, root, type: 'stylesheets', ext: EXT)
    end

    def can_handle?(filename)
      super(filename, real_ext: 'css')
    end

    def compile(filename)
      ::Stylus.compile File.new(file_path(filename)), **css_options
    end

    def css_options
      {
        'development' => {
          compress: false
        },
        'test' => {
          compress: false
        }
      }[@env]
    end
  end

  class CoffeeScript < SimpleAsset
    require 'coffee-script'

    EXT = 'coffee'.freeze

    def initialize(env, root)
      super(env, root, type: 'javascripts', ext: EXT)
    end

    def can_handle?(filename)
      super(filename, real_ext: 'js')
    end

    def compile(filename)
      ::CoffeeScript.compile File.read(file_path(filename))
    end
  end

  class ES6 < SimpleAsset
    require 'babel/transpiler'

    EXT = 'es6'.freeze

    def initialize(env, root)
      super(env, root, type: 'javascripts', ext: EXT)
    end

    def can_handle?(filename)
      super(filename, real_ext: 'js')
    end

    def compile(filename)
      ::Babel::Transpiler.transform File.read(file_path(filename))
    end
  end

  class NullCompiler
    def can_handle?(_)
      fail UnhandableAsset
    end
  end
end
