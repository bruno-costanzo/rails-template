class FeedbacksController < ApplicationController
  def new
    @feedback = Current.user.feedbacks.build
  end

  def create
    @feedback = Current.user.feedbacks.build(feedback_params)
    if @feedback.save
      redirect_to root_path, notice: "Thanks for the feedback!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def feedback_params
    params.expect(feedback: [ :message, photos: [] ])
  end
end
