class Evil::Client
  #
  # @abstract
  # Base class for mutable containers of client-specific definitions
  # of nested scopes and operations along with a corresponding [#settings] class
  # subclassing [Evil::Client::Settings]
  #
  # Every concrete container defines its only DSL for scope/operation
  # definitions.
  #
  class Schema
    Names.clean(self) # Remove unnecessary methods from the instance

    # Loads concrete implementations of the abstract schema
    require_relative "schema/operation"
    require_relative "schema/scope"

    # The name of current schema which is unique for the existing [#parent],
    # or equals to client class name without any [#parent] (root scope name).
    #
    # @return [String]
    #
    attr_reader :name

    # Scope schema the operation belongs to
    #
    # Only the root schema has no parents.
    # Its definitions are shared by all operations
    #
    # @return [Evil::Client::Schema::Scope, nil]
    #
    attr_reader :parent

    # Back reference to client the schema belongs to
    #
    # @return [Evil::Client]
    #
    attr_reader :client

    # The human-friendly representation of the schema
    #
    # @example
    #   "MyClient.users.fetch" # custom operation's schema
    #
    # @return [String]
    #
    def to_s
      [parent, name].compact.join(".")
    end
    alias_method :to_str,  :to_s
    alias_method :inspect, :to_s

    # The settings class inherited from the [#parent]'s one
    #
    # @return [Class]
    #
    def settings
      @settings ||= (parent&.settings || Settings).for(self)
    end

    # Adds an option to the [#settings] class
    #
    # @param  (see Evil::Client::Model.option)
    # @option (see Evil::Client::Model.option)
    # @return [self]
    #
    def option(key, type = nil, **opts)
      settings.option(key, type, **opts)
      self
    end

    # Adds a memoized method to the [#settings] class
    #
    # @param  (see Evil::Client::Model.let)
    # @return [self]
    #
    def let(key, &block)
      settings.let(key, &block)
      self
    end

    # Adds validator to the [#settings] class
    #
    # @param  (see Evil::Client::Model.validate)
    # @return [self]
    #
    def validate(*_args, &block)
      settings.validate(&block)
      self
    end

    private

    def initialize(parent, name = nil)
      if parent.is_a? self.class
        @parent = parent
        @client = parent&.client
        @name   = name
      else
        @client = parent
        @name   = parent.name
      end
    end
  end
end
