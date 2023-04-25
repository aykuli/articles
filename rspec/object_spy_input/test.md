


```ruby
describe File do
  let(:user) { instance_double(User) }
  let(:other_user) { instance_double(User) }
  let(:file) { instance_double(File) }
  let(:order) { instance_double(Order) }

  before do
    allow(file).to receive(:order).and_return(order)
  end

  context 'user is inspector' do
    before do
      allow(user).to receive(:inspector?).and_return(true)
      allow(file).to receive(:suggestion?).and_return(true)
      allow(file).to receive(:conclusion?).and_return(false)
      allow(order).to receive(:created?).and_return(true)
    end

    it 'can upload file' do
      expect(order.file).to be file
    end
  end
end
```
