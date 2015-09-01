class AuthorizationController < WebsocketRails::BaseController
  def authorize_peer_message
    # The channel name and channel user_id will be passed inside the message Hash
    channel = Channel.find_by_name(message[:channel])
    channel_user = User.find(message[:user_id])
    if current_user.can_message?(channel_user) # You would need to implement the #can_message method on User
      authorize_peer_message
    else
      deny_peer_message
    end
  end
end