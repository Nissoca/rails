require "abstract_unit"
require "active_job"
require "mailers/params_mailer"

class ParameterizedTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @previous_logger = ActiveJob::Base.logger
    ActiveJob::Base.logger = Logger.new(nil)

    @previous_delivery_method = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = :test

    @previous_deliver_later_queue_name = ActionMailer::Base.deliver_later_queue_name
    ActionMailer::Base.deliver_later_queue_name = :test_queue
    ActionMailer::Base.delivery_method = :test

    @mail = ParamsMailer.with(inviter: "david@basecamp.com", invitee: "jason@basecamp.com").invitation
  end

  teardown do
    ActiveJob::Base.logger = @previous_logger
    ParamsMailer.deliveries.clear

    ActionMailer::Base.delivery_method = @previous_delivery_method
    ActionMailer::Base.deliver_later_queue_name = @previous_deliver_later_queue_name
  end

  test "parameterized headers" do
    assert_equal(["jason@basecamp.com"], @mail.to)
    assert_equal(["david@basecamp.com"], @mail.from)
    assert_equal("So says david@basecamp.com", @mail.body.encoded)
  end

  test "should enqueue the email with params" do
    assert_performed_with(job: ActionMailer::Parameterized::DeliveryJob, args: ["ParamsMailer", "invitation", "deliver_now", { inviter: "david@basecamp.com", invitee: "jason@basecamp.com" } ]) do
      @mail.deliver_later
    end
  end
end
