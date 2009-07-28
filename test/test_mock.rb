class MockErrors
        def initialize
                @errors = []
        end

        def add_to_base(msg)
                @errors << msg
        end

        def on_base
                @errors
        end
end

class MockDomain
        attr_accessor :name, :type, :valid, :primary_ns

        def initialize(values = {})
                self.type = "MASTER"
                self.valid = true

                values.map do |a,v|
                        self.send( "#{a}=", v )
                end

        end

        def master?
                self.type == "MASTER"
        end

        def valid?
                self.valid
        end

        def errors
                @errors ||= MockErrors.new
        end
end

module Hook
  def self.config_for(subclass)
    {}
  end
end
