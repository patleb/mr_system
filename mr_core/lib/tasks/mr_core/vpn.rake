namespace :vpn do
  desc "-- [options] VPN Update IP"
  task :update_ip => :environment do |t|
    MrCore::Vpn::UpdateIp.new(self, t).run
  end
end