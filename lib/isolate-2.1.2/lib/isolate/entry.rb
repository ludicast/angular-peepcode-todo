require "isolate/events"
require "rubygems"
require "rubygems/command"
require "rubygems/dependency_installer"
require "rubygems/requirement"
require "rubygems/version"

module Isolate

  # An isolated Gem, with requirement, environment restrictions, and
  # installation options. Generally intended for internal use. This
  # class exposes lifecycle events for extension, see Isolate::Events
  # for more information.

  class Entry
    include Events

    # Which environments does this entry care about? Generally an
    # Array of Strings. An empty array means "all", not "none".

    attr_reader :environments

    # What's the name of this entry? Generally the name of a gem.

    attr_reader :name

    # Extra information or hints for installation. See +initialize+
    # for well-known keys.

    attr_reader :options

    # What version of this entry is required? Expressed as a
    # Gem::Requirement, which see.

    attr_reader :requirement

    # Create a new entry. Takes +sandbox+ (currently an instance of
    # Isolate::Sandbox), +name+ (as above), and any number of optional
    # version requirements (generally strings). Options can be passed
    # as a trailing hash. Well-known keys:
    #
    # :args:: Command-line build arguments. Passed to the gem at
    #         installation time.
    #
    # :source:: An alternative RubyGems source for this gem.

    def initialize sandbox, name, *requirements
      @environments = []
      @file         = nil
      @name         = name
      @options      = {}
      @requirement  = Gem::Requirement.default
      @sandbox      = sandbox

      if /\.gem$/ =~ @name && File.file?(@name)
        @file = File.expand_path @name

        @name = File.basename(@file, ".gem").
          gsub(/-#{Gem::Version::VERSION_PATTERN}$/, "")
      end

      update(*requirements)
    end

    # Activate this entry. Fires <tt>:activating</tt> and
    # <tt>:activated</tt>.

    def activate
      fire :activating, :activated do
        Gem.activate name, *requirement.as_list
      end
    end

    # Install this entry in the sandbox. Fires <tt>:installing</tt>
    # and <tt>:installed</tt>.

    def install
      old = Gem.sources.dup

      begin
        fire :installing, :installed do
          installer = Gem::DependencyInstaller.new :development => false,
            :generate_rdoc => false, :generate_ri => false,
            :install_dir => @sandbox.path

          Gem.sources += Array(options[:source]) if options[:source]
          Gem::Command.build_args = Array(options[:args]) if options[:args]

          installer.install @file || name, requirement
        end
      ensure
        Gem.sources = old
        Gem::Command.build_args = nil
      end
    end

    # Is this entry interested in +environment+?

    def matches? environment
      environments.empty? || environments.include?(environment)
    end

    # Is this entry satisfied by +spec+ (generally a
    # Gem::Specification)?

    def matches_spec? spec
      name == spec.name and requirement.satisfied_by? spec.version
    end

    # The Gem::Specification for this entry.

    def specification
      Gem.source_index.find_name(name, requirement).first
    end

    # Updates this entry's environments, options, and
    # requirement. Environments and options are merged, requirement is
    # replaced. Fires <tt>:updating</tt> and <tt>:updated</tt>.

    def update *reqs
      fire :updating, :updated do
        @environments |= @sandbox.environments
        @options.merge! reqs.pop if Hash === reqs.last
        @requirement = Gem::Requirement.new reqs unless reqs.empty?
      end

      self
    end
  end
end
