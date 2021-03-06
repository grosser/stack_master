module StackMaster
  module Commands
    class Delete
      include Command
      include StackMaster::Prompter

      def initialize(region, stack_name)
        @region = region
        @stack_name = stack_name
        @from_time = Time.now
      end

      def perform

        return unless check_exists

        unless ask?("Really delete stack #{@stack_name} (y/n)? ")
          StackMaster.stdout.puts "Stack update aborted"
          return
        end

        delete_stack
        tail_stack_events unless StackMaster.quiet?
      end

      private

      def delete_stack
        cf.delete_stack({stack_name: @stack_name})
      end

      def check_exists
        cf.describe_stacks({stack_name: @stack_name})
        true
      rescue Aws::CloudFormation::Errors::ValidationError
        StackMaster.stdout.puts "Stack does not exist"
        false
      end

      def cf
        StackMaster.cloud_formation_driver
      end

      def tail_stack_events
        StackEvents::Streamer.stream(@stack_name, @region, io: StackMaster.stdout, from: @from_time)
        StackMaster.stdout.puts "Stack deleted"
      rescue Aws::CloudFormation::Errors::ValidationError
        # Unfortunately the stack as a tendency of going away before we get the final delete event.
        StackMaster.stdout.puts "Stack deleted"
      end
    end
  end
end
