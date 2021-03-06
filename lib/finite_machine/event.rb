# encoding: utf-8

module FiniteMachine
  # A class representing event with transitions
  class Event
    include Comparable
    include Threadable

    # The name of this event
    attr_threadsafe :name

    # The state transitions for this event
    attr_threadsafe :state_transitions

    # The reference to the state machine for this event
    attr_threadsafe :machine

    # The silent option for this transition
    attr_threadsafe :silent

    # Initialize an Event
    #
    # @api private
    def initialize(machine, attrs = {})
      @machine = machine
      @name    = attrs.fetch(:name, DEFAULT_STATE)
      @silent  = attrs.fetch(:silent, false)
      @state_transitions = []
      # TODO: add event conditions
      freeze
    end

    protected :machine

    # Add transition for this event
    #
    # @param [FiniteMachine::Transition] transition
    #
    # @example
    #   event << FiniteMachine::Transition.new machine, :a => :b
    #
    # @return [nil]
    #
    # @api public
    def <<(transition)
      sync_exclusive do
        Array(transition).flatten.each { |trans| state_transitions << trans }
      end
    end
    alias_method :add, :<<

    # Find next transition
    #
    # @return [FiniteMachine::Transition]
    #
    # @api private
    def next_transition
      sync_shared do
        state_transitions.find { |transition| transition.current? } ||
        state_transitions.first
      end
    end

    # Find transition matching conditions
    #
    # @param [Array[Object]] args
    #
    # return FiniteMachine::TransitionChoice
    #
    # @api private
    def find_transition(*args)
      sync_shared do
        state_transitions.find do |trans|
          trans.current? && trans.check_conditions(*args)
        end
      end
    end

    # Trigger this event
    #
    # If silent option is passed the event will not fire any callbacks
    #
    # @example
    #   transition = Transition.create(machine, {})
    #   transition.call
    #
    # @return [nil]
    #
    # @api public
    def call(*args, &block)
      sync_exclusive do
        event_transition = next_transition
        if silent
          event_transition.call(*args, &block)
        else
          machine.send(:transition, event_transition, *args, &block)
        end
      end
    end

    # Return event name
    #
    # @return [String]
    #
    # @api public
    def to_s
      name.to_s
    end

    # Return string representation
    #
    # @return [String]
    #
    # @api public
    def inspect
      "<##{self.class} @name=#{name}, @silent=#{silent}, " \
      "@transitions=#{state_transitions.inspect}>"
    end

    # Compare whether the instance is greater, less then or equal to other
    #
    # @return [-1 0 1]
    #
    # @api public
    def <=>(other)
      other.is_a?(self.class) && [name, silent, state_transitions] <=>
        [other.name, other.silent, other.state_transitions]
    end
    alias_method :eql?, :==
  end # Event
end # FiniteMachine
