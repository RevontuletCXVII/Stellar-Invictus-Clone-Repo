class DisappearWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(player_id)
    user = User.find(player_id)
    if user
      # Remove one from online
      user.update_columns(online: user.online - 1) if user.online > 0
      
      # If user is not docked and now closed last connection
      if !user.docked and user.online == 0
        # Tell everyone in location that user warped out
        ActionCable.server.broadcast("location_#{user.location.id}", method: 'player_warp_out', name: user.full_name)
        
        # Remove user as target from every player that targeted him
        User.where(target_id: user.id).each do |u|
          u.update_columns(target_id: nil)
          ActionCable.server.broadcast("player_#{u.id}", method: 'refresh_target_info')
        end
      end
    end
  end
end