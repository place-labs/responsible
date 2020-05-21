require "../spec_helper"

describe Responsible::ResponseType do
  describe ".from" do
    it "parses from a a HTTP::Status" do
      type = Responsible::ResponseType.from HTTP::Status.new(100)
      type.should eq(Responsible::ResponseType::Informational)
    end
  end
end
