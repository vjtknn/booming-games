require 'json'
require 'bunny'
class Chat

#Module that display send and recived message
#in right format
  def display_message(user, message)
    puts "#{user}: #{message}"
  end

#The initialzation module that ask user for their nama and informs them that now they are in the chat room 
#and to send message they need to press Enter
  def initialize
    print "Type in your name: "
    @current_user = gets.strip
    puts "Hi #{@current_user}, you just joined a chat room! Type your message in and press enter."

#The application starts connection to RabbutMQ server and creates chanel and type of communicaton (fanout)
    conn = Bunny.new
    conn.start
    @channel = conn.create_channel
    @exchange = @channel.fanout("super.chat")


    listen_for_messages
  end

#Module that listen and recive messages from 
#"Hello" queue and formats them to display in
#"User + Message" format
  def listen_for_messages
    queue = @channel.queue("Hello")
    queue.bind(@exchange).subscribe do |delivery_info, metadata, payload|
    data = JSON.parse(payload)
    display_message(data['user'], data['message'])
  
#Part that after uncommenting allows to chat beetwen two 
#chat.rb apps (send and recive messages)
    #user = data.match(" ").pre_match
    #message = data.match(" ").post_match
    #display_message(user, message)
  end
  end

#Module that sends message 
  def publish_message(user, message)
    msg = "#{user} #{message}"
    @exchange.publish(msg.to_json)
#For better     
    if (user == @current_user)
      display_message("You", message)
    end
  end

#Module that gather messages from user and sends it to publishing module
  def wait_for_message
    message = gets.strip
    publish_message(@current_user, message)
    wait_for_message
  end

end


chat = Chat.new
chat.wait_for_message
