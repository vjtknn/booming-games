
defmodule ElixirChat do

  def start do
    user = IO.gets("Type in your name: ") |> String.strip
    IO.puts "Hi #{user}, you just joined a chat room! Type your message in and press enter."

#The application establishes connection to RabbitMQ server, creates channel and queue
    {:ok, conn} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(conn)
    {:ok, queue_data } = AMQP.Queue.declare(channel, "Hello")


    AMQP.Exchange.fanout(channel, "super.chat")
    AMQP.Queue.bind(channel, queue_data.queue, "super.chat")
    AMQP.Basic.consume(channel, queue_data.queue, nil, no_ack: true)

    
    listen_for_messages(channel, queue_data.queue)
    wait_for_message(user, channel)
  end

#The module that waits for message from user and redirects message to publishing module
  def wait_for_message(user, channel) do
   message = IO.gets("") |> String.strip
   publish_message(user, message, channel)
   IO.puts "#{user} #{message}"
   wait_for_message(user, channel)
  end

#The module that recive and display messages
  def listen_for_messages(channel, queue_name) do
    receive do
      {:basic_deliver, payload, _meta} ->
      data = String.split("#{payload}", " ")
      sender = hd(data)
      message = tl(data) |> Enum.join(" ")
      IO.puts '#{sender}: #{message}'
      listen_for_messages(channel, queue_name)
    end
  end

#Publishing the messages module
  def publish_message(user, message, channel) do
    { :ok, data } = JSON.encode([user: user, message: message])
    AMQP.Basic.publish(channel, "super.chat", "Hello", data)
  end

end

ElixirChat.start