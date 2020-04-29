class TasksController < ApplicationController
  before_action :set_task, only: %i[edit update destroy]

  def index
    @tasks = Task.includes(:category).order(id: :desc)
  end

  def new
    @task = Task.new
  end

  def create
    @task = Task.new(task_params)
    if @task.save
      redirect_to tasks_path, notice: '登録しました'
    else
      render :new
    end
  end

  def edit; end

  def update
    if @task.update(task_params)
      redirect_to tasks_path, notice: '更新しました'
    else
      render :edit
    end
  end

  def destroy
    @task.destroy!
    redirect_to tasks_path, notice: '削除しました'
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :body, :category_id, :priority, :status, :notice, :code, :limited_on)
  end
end