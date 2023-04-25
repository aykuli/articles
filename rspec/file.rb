class Suggestion
  def initialize(type:)
    @type = type
    @comment = nil
  end

  def attach(argument, user)
    @comment = argument if user.inspector?
    @comment
  end

  def accept? = @type == 'accept'
  def decline? = @type == 'decline'

  def comment = @comment
end

class User
  def inspector? = true
end

RSpec.describe Suggestion do
  let(:user) { instance_double(User) }
  let(:other_user) { instance_double(User) }
  let(:suggestion) { Suggestion.new(type: 'accept') }

  let(:comment) { 'my argument' }

  context 'when user is inspector' do
    before do
      allow(user).to receive(:inspector?).and_return(true)
    end

    it 'he can leave a comment' do
      suggestion.attach(comment, user)

      expect(suggestion.comment).to eq(comment)
    end
  end

  context 'when user is not inspector' do
    before do
      allow(user).to receive(:inspector?).and_return(false)
    end

    it 'he can not leave a comment' do
      suggestion.attach(comment, user)

      expect(suggestion.comment).to be nil
    end
  end
end