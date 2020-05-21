require "../spec_helper"

describe Responsible::Response do
  it "supports local handlers" do
    WebMock.stub(:get, "www.example.com")
    has_run = false

    response = ~HTTP::Client.get("www.example.com")

    response.on_success do
      has_run = true
    end

    has_run.should be_true
  end

  describe "#>>" do
    it "deserializes a JSON body" do
      WebMock.stub(:get, "www.example.com").to_return(
        headers: { "Content-Type" => "application/json" },
        body: <<-JSON
          {"value":"foo"}
        JSON
      )
      response = ~HTTP::Client.get("www.example.com") >> NamedTuple(value: String)
      response[:value].should eq("foo")
    end

    it "raises an exception on a non-successful response" do
      WebMock.stub(:get, "www.example.com").to_return(status: 500)
      expect_raises(Responsible::ServerError) do
        ~HTTP::Client.get("www.example.com") >> NamedTuple(value: String)
      end
    end

    it "allows extraction of unsuccessful responses in handlers" do
      WebMock.stub(:get, "www.example.com").to_return(
        status: 500,
        headers: { "Content-Type" => "application/json" },
        body: <<-JSON
          {"message":"computer says no"}
        JSON
      )
      response = ~HTTP::Client.get("www.example.com")

      response.on_server_error do
        error = response >> NamedTuple(message: String)
        error[:message].should eq("computer says no")
      end
    end

    it "raises an exception for unsupported content types" do
      WebMock.stub(:get, "www.example.com").to_return(
        headers: { "Content-Type" => "text/csv" },
        body: "this,is,a,csv"
      )
      expect_raises(Responsible::Error) do
        ~HTTP::Client.get("www.example.com") >> Array(String)
      end
    end
  end
end
