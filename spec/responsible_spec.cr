require "./spec_helper"

def test_get(url : String, type : T.class) : T forall T
  Responsible.parse_to_return_type do
    HTTP::Client.get(url)
  end
end

describe Responsible do
  it "supports registering global handlers" do
    WebMock.stub(:get, "www.example.com")
    has_run = false

    Responsible.on_success do
      has_run = true
    end

    ~HTTP::Client.get("www.example.com")

    has_run.should be_true
  end

  it "runs the correct handler" do
    WebMock.stub(:get, "www.example.com").to_return(status: 500)
    error = false
    success = false

    Responsible.on_success do
      success = true
    end

    Responsible.on_server_error do
      error = true
    end

    ~HTTP::Client.get("www.example.com")

    error.should be_true
    success.should be_false
  end

  describe ".parse_to" do
    it "supports wrapping an expression" do
      WebMock.stub(:get, "www.example.com").to_return(
        headers: { "Content-Type" => "application/json" },
        body: %({"value":"foo"})
      )
      result = Responsible.parse_to(NamedTuple(value: String)) do
        HTTP::Client.get("www.example.com") 
      end
      result[:value].should eq("foo")
    end
  end

  describe ".parse_to?" do
    it "returns nil for incompatible types" do
      WebMock.stub(:get, "www.example.com").to_return(
        headers: { "Content-Type" => "application/json" },
        body: %(42)
      )
      result = Responsible.parse_to?(Bool) do
        HTTP::Client.get("www.example.com")
      end
      result.should be_nil
    end
  end

  describe ".parse_to_return_type" do
    it "supports wrapping an expression" do
      WebMock.stub(:get, "www.example.com").to_return(
        headers: { "Content-Type" => "application/json" },
        body: %({"a":"foo","b":42})
      )
      result = test_get("www.example.com", NamedTuple(a: String, b: Int32))
      result[:a].should eq("foo")
    end
  end

end
