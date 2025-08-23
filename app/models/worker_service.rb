class WorkerService < ApplicationRecord
  belongs_to :worker_profile
  belongs_to :service
end
