defmodule Sender.Core.Email.Mailer do
  @moduledoc false
  use Bamboo.Mailer, otp_app: :sender
  # require Logger
  # @sleep_time 1_000

  # def deliver_now(email) do
  #   :timer.sleep(@sleep_time)
  #   email
  # end
end