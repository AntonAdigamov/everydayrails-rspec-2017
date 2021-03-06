require 'rails_helper'

RSpec.feature "Projects", type: :system do
  let(:user) { FactoryBot.create(:user) }
  let!(:project) { FactoryBot.create(:project, :due_today, owner: user) }

  it 'creates a new project as a user' do
    sign_in(user)

    visit root_path

    expect {
      click_link 'New Project'
      fill_in 'Name', with: 'Test Project'
      fill_in 'Description', with: 'Trying out Capybara'
      click_button 'Create Project'
    }.to change(user.projects, :count).by(1)

    aggregate_failures do
      expect(page).to have_content 'Project was successfully created'
      expect(page).to have_content 'Test Project'
      expect(page).to have_content "Owner: #{user.name}"
    end

    expect {
      visit projects_path
      click_link 'New Project'
      click_link 'Cancel'

      expect(current_path).to eq(projects_path)
    }.to_not change(user.projects, :count)
  end

  it 'updates the project as a user' do
    sign_in(user)

    visit root_path
    click_link project.name
    click_link 'Edit'
    fill_in 'Name', with: project.name.reverse
    fill_in 'Description', with: project.description.reverse
    select 1.year.from_now.year, from: 'project_due_on_1i'
    select 1.month.from_now.strftime("%B"), from: 'project_due_on_2i'
    select 1.day.from_now.day, from: 'project_due_on_3i'
    click_button 'Update Project'

    expect(page).to have_content project.name.reverse
    expect(page).to have_content project.description.reverse
    expect(page).to_not have_content project.name
    expect(page).to_not have_content project.description
    expect(page).to have_content(
      1.month.from_now.strftime("%B") + ' ' +
        1.day.from_now.strftime('%d').to_s + ', ' +
          1.year.from_now.year.to_s
    )

    click_link 'Edit'
    click_link 'Cancel'

    expect(current_path).to eq(project_path(project))
  end

  it 'completes a project as a user' do
    user = FactoryBot.create(:user)
    project = FactoryBot.create(:project, owner: user)
    login_as user, scope: :user

    visit project_path(project)
    expect(page).to_not have_content('Completed')
    click_button 'Complete'

    expect(project.reload.completed?).to be(true)
    expect(page).to have_content('Congratulations, this project is complete!')
    expect(page).to have_content('Completed')
    expect(page).to_not have_button('Complete')
  end
end
