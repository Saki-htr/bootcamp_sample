# frozen_string_literal: true

require 'application_system_test_case'

class HomeTest < ApplicationSystemTestCase
  test 'GET / without sign in' do
    logout
    visit '/'
    assert_equal 'FJORD BOOT CAMP（フィヨルドブートキャンプ）', title
  end

  test 'GET /' do
    visit_with_auth '/', 'komagata'
    assert_equal 'ダッシュボード | FJORD BOOT CAMP（フィヨルドブートキャンプ）', title
  end

  test 'GET / without github account ' do
    visit_with_auth '/', 'hajime'
    within('.card-list__item-link.is-github_account') do
      assert_text 'GitHubアカウントを登録してください。'
    end
  end

  test 'GET / with github account' do
    user = users(:hajime)
    user.update!(github_account: 'hajime')
    visit_with_auth '/', 'hajime'
    assert_no_selector '.card-list__item-link.is-github_account'
  end

  test 'GET / without discord_account' do
    visit_with_auth '/', 'hajime'
    within('.card-list__item-link.is-discord_account') do
      assert_text 'Discordアカウントを登録してください。'
    end
  end

  test 'GET / with discord_account' do
    user = users(:hajime)
    user.update!(discord_account: 'hajime#1111')
    visit_with_auth '/', 'hajime'
    assert_no_selector '.card-list__item-link.is-discord_account'
  end

  test 'show latest announcements on dashboard' do
    visit_with_auth '/', 'hajime'
    assert_text '後から公開されたお知らせ'
    assert_no_text 'wipのお知らせ'
  end

  test '現役生の場合にニコニコカレンダーが表示されているか' do
    visit_with_auth '/', 'hajime'
    assert_text 'ニコニコカレンダー'
  end

  test '卒業生の場合にニコニコカレンダーが表示されていないか' do
    visit_with_auth '/', 'sotugyou'
    assert_no_text 'ニコニコカレンダー'
  end

  test '管理者の場合にニコニコカレンダーが表示されていないか' do
    visit_with_auth '/', 'komagata'
    assert_no_text 'ニコニコカレンダー'
  end
end
