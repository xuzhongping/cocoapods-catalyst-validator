require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Validator do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ validator }).should.be.instance_of Command::Validator
      end
    end
  end
end

