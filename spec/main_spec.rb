require "davinci_threader"


describe DavinciThreader do


  context "Initial test" do
    it "should work" do


      DavinciThreader::Main.new do |t|

        t.show_output = false
        t.rpm = 3000
        records = 500
        t.total = records


        t.synchronous_action do |_item|
          print "\r#{t.synchronous_items.count-1}  "
          sleep(rand(0.04..0.14))
        end


        records.times do |i|
          t.make_thread(i) do |_i|
            t.synchronous_items << _i
            t.success
          end
        end

      end
      print "\n"


    end
  end


end
