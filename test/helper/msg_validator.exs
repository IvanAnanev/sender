defmodule Sender.Helper.MsgValidatorTest do
  use ExUnit.Case

  alias Sender.Helper.MsgValidator, as: MsgValidator

  test "with good msg" do
    msg = %{
      "id" => "12",
      "msg" => %{"subject" => "tender_open", "text" => "text 1"},
      "priority" => "highest",
      "recipient" => "ivcheg@gmail.com",
      "send_date" => "2018-01-18T11:36:01.089987Z",
      "type" => "email"
    }

    assert MsgValidator.exec(msg) == {:ok, msg}
  end

  test "with bad msg" do
    bad_msg = %{
      "id" => 12,
      "msg" => %{"subject" => "tender_open", "text" => "text 1"},
      "priority" => 12,
      "recipient" => 12,
      "send_date" => "str",
      "type" => :email
    }

    assert MsgValidator.exec(bad_msg) ==
             {:error,
              "The msg %{\"id\" => 12, \"msg\" => %{\"subject\" => \"tender_open\", \"text\" => \"text 1\"}, \"priority\" => 12, \"recipient\" => 12, \"send_date\" => \"str\", \"type\" => :email} have this errors: %{\"id\" => \"it's bad\", \"priority\" => \"it's bad\", \"recipient\" => \"it's bad\", \"send_date\" => \"can't parse datetime\", \"type\" => \"it's bad\"}"}
  end
end
