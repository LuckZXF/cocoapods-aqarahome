require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Aqarahome do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ aqarahome }).should.be.instance_of Command::Aqarahome
      end
    end
  end
end

