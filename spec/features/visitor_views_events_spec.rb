require "rails_helper"

feature "Views events" do
  scenario "sees all event details" do
    create_events

    visit_events_path

    expect(page).to have_content(first_event.title)
    expect(page).to have_content(first_event.description)
    expect(page).to have_content(first_event.end_date.to_formatted_s(:short))
    expect(page).to have_content(second_event.title)
    expect(page).to have_content(second_event.description)
    expect(page).to have_content(second_event.end_date.to_formatted_s(:short))
  end

  scenario "sees pagination controls" do
    allow(Kaminari.config).to receive(:default_per_page).and_return(1)

    create_events

    visit_events_path

    expect(page).to have_content(first_event.title)
    expect(page).to have_content(first_event.description)
    expect(page).to have_content(first_event.end_date.to_formatted_s(:short))

    expect(page).not_to have_content(second_event.title)

    expect(page).to have_content("Next")
    expect(page).to have_content("Last")

    click_on "Last"

    expect(page).not_to have_content(first_event.title)

    expect(page).to have_content(second_event.title)
    expect(page).to have_content(second_event.description)
    expect(page).to have_content(second_event.end_date.to_formatted_s(:short))

    expect(page).to have_content("Prev")
    expect(page).to have_content("First")
  end  

  scenario "see event in the correct order" do
    # ..
  end

  private

  def create_events
    first_event
    second_event
  end

  def first_event
    @first_event ||= create(:event)
  end

  def second_event
    @second_event ||= create(:event)
  end

  def visit_events_path
    visit root_path
    click_link(t("application.header.events"), match: :first)
  end
end
