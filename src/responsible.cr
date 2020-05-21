require "./responsible/**"
require "./core_ext/**"

module Responsible
  HANDLERS = {} of ResponseType => Action

  {% for type in ResponseType.constants %}
    # Registers an `Action` to execute every on every {{type}} response.
    def self.on_{{type.underscore}}(&block : Action) : Nil
      HANDLERS[ResponseType::{{type}}] = block
    end
  {% end %}
end
