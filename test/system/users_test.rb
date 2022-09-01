# frozen_string_literal: true

require 'application_system_test_case'

class UsersTest < ApplicationSystemTestCase
  test 'show listing all users' do
    visit_with_auth users_path, 'kimura'
    assert_equal '全てのユーザー | FBC', title
    assert_selector 'h2.page-header__title', text: 'ユーザー'
  end

  test 'show profile' do
    visit_with_auth "/users/#{users(:hatsuno).id}", 'hatsuno'
    assert_equal 'hatsuno | FBC', title
  end

  test 'autolink profile when url is included' do
    url = 'https://bootcamp.fjord.jp/'
    visit_with_auth edit_current_user_path, 'kimura'
    fill_in 'user_description', with: "木村です。ブートキャンプはじめました。#{url}"
    click_button '更新する'
    assert_link url, href: url
  end

  test 'access by other users' do
    user = users(:hatsuno)
    visit_with_auth edit_admin_user_path(user.id), 'mentormentaro'
    assert_text '管理者としてログインしてください'
  end

  test 'graduation date is displayed' do
    visit_with_auth "/users/#{users(:mentormentaro).id}", 'komagata'
    assert_no_text '卒業日'

    visit "/users/#{users(:sotugyou).id}"
    assert_text '卒業日'
  end

  test 'retired date is displayed' do
    visit_with_auth "/users/#{users(:yameo).id}", 'komagata'
    assert_text '退会日'
    visit "/users/#{users(:sotugyou).id}"
    assert_no_text '退会日'
  end

  test 'retire reason is displayed when login user is admin' do
    visit_with_auth "/users/#{users(:yameo).id}", 'komagata'
    assert_text '退会理由'
    visit "/users/#{users(:sotugyou).id}"
    assert_no_text '退会理由'
  end

  test "retire reason isn't displayed when login user isn't admin" do
    visit_with_auth "/users/#{users(:yameo).id}", 'kimura'
    assert_no_text '退会理由'
  end

  test "normal user can't see unchecked number table" do
    visit_with_auth "/users/#{users(:hatsuno).id}", 'hatsuno'
    assert_equal 0, all('.admin-table').length
  end

  test 'show users role' do
    visit_with_auth "/users/#{users(:komagata).id}", 'komagata'
    assert_text '管理者'

    visit_with_auth "/users/#{users(:mentormentaro).id}", 'mentormentaro'
    assert_text 'メンター'

    visit_with_auth "/users/#{users(:advijirou).id}", 'advijirou'
    assert_text 'アドバイザー'

    visit_with_auth "/users/#{users(:kensyu).id}", 'kensyu'
    assert_text '研修生'

    visit_with_auth "/users/#{users(:sotugyou).id}", 'sotugyou'
    assert_text '卒業生'
  end

  test 'show completed practices' do
    visit_with_auth "/users/#{users(:kimura).id}", 'machida'
    assert_text 'OS X Mountain Lionをクリーンインストールする'
    assert_no_text 'Terminalの基礎を覚える'
  end

  test 'show last active date and time of access user only to mentors' do
    travel_to Time.zone.local(2014, 1, 1, 0, 0, 0) do
      visit_with_auth login_path, 'kimura'
    end

    travel_to Time.zone.local(2014, 1, 1, 1, 0, 0) do
      visit login_path
    end

    travel_to Time.zone.local(2014, 1, 1, 2, 0, 0) do
      visit logout_path
    end

    visit_with_auth "/users/#{users(:kimura).id}", 'komagata'
    assert_text '最終活動日時'
    assert_text '2014年01月01日(水) 01:00'

    visit_with_auth "/users/#{users(:kimura).id}", 'hatsuno'
    assert_no_text '最終活動日時'

    visit_with_auth "/users/#{users(:neverlogin).id}", 'komagata'
    assert_text '最終活動日時'
    assert_no_text '2022年07月11日(月) 09:00'

    visit_with_auth "/users/#{users(:neverlogin).id}", 'hatsuno'
    assert_no_text '最終活動日時'
  end

  test 'show inactive message on users page' do
    travel_to Time.zone.local(2014, 1, 1, 0, 0, 0) do
      visit_with_auth '/', 'kimura'
    end

    visit_with_auth '/users', 'komagata'
    assert_no_selector 'div.users-item.inactive'
    assert_text '1ヶ月以上ログインがありません'

    visit_with_auth '/users', 'hatsuno'
    assert_no_selector 'div.users-item.inactive'
    assert_no_text '1ヶ月以上ログインがありません'
  end

  test 'show inactive users only to mentors' do
    User.inactive_students_and_trainees.each do |user|
      user.update_columns(last_activity_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    end

    visit_with_auth '/', 'komagata'
    assert_no_text '1ヶ月以上ログインのないユーザー'

    users(:kimura).update!(
      last_activity_at: Time.zone.local(2020, 1, 1, 0, 0, 0)
    )

    visit_with_auth '/', 'komagata'
    assert_text '1ヶ月以上ログインのないユーザー'

    visit_with_auth '/', 'hatsuno'
    assert_no_text '1ヶ月以上ログインのないユーザー'
  end

  test 'student access control' do
    visit_with_auth '/users', 'kimura'
    assert_no_text '全員'
    assert_no_text '就職活動中'

    visit 'users?target=retired'
    assert_no_text '退会'
  end

  test 'advisor access control' do
    visit_with_auth '/users', 'advijirou'
    assert_no_text '全員'
    assert find_link('就職活動中')

    visit 'users?target=retired'
    assert_no_text '退会'
  end

  test 'mentor access control' do
    visit_with_auth '/users', 'mentormentaro'
    assert find_link('就職活動中')
    assert find_link('全員')
  end

  test 'admin access control' do
    visit_with_auth '/users', 'komagata'
    assert find_link('就職活動中')
    assert find_link('全員')
  end

  test 'push question tab for showing all the recoreded questions' do
    visit_with_auth "/users/#{users(:hatsuno).id}", 'hatsuno'
    click_link '質問'
    assert_text '質問のタブの作り方'
    assert_text '質問のタブに関して。。。追加質問'
  end

  test 'show welcome message' do
    visit_with_auth '/', 'hatsuno'
    assert_text 'ようこそ'
  end

  test 'not show welcome message' do
    visit_with_auth practice_path(practices(:practice1).id), 'hatsuno'
    click_button '着手'
    visit '/'
    assert_no_text 'ようこそ'
  end

  test 'paging niconico_calendar' do
    visit_with_auth root_path, 'hatsuno'
    today = Time.current
    last_month = today.prev_month
    visit user_path(users(:hajime).id)
    within '.niconico-calendar-nav' do
      assert_text "#{today.year}年#{today.month}月"
      find('.niconico-calendar-nav__previous').click
      assert_text "#{last_month.year}年#{last_month.month}月"
    end
  end

  test 'show mark to today on niconico_calendar' do
    today = Time.current
    visit_with_auth root_path, 'hatsuno'
    visit user_path(users(:hajime).id)
    assert_selector '.niconico-calendar__day.is-today'
    target_day = find('.niconico-calendar__day.is-today').text
    assert_equal today.day.to_s, target_day
  end

  test 'not show mark to today on niconico_calendar' do
    visit_with_auth root_path, 'hatsuno'
    visit user_path(users(:hajime).id)
    find('.niconico-calendar-nav__previous').click
    assert_no_selector '.niconico-calendar__day.is-today'
  end

  test 'show times link on user page' do
    kimura = users(:kimura)

    visit_with_auth "/users/#{kimura.id}", 'hatsuno'
    assert_no_link(href: 'https://discord.com/channels/715806612824260640/123456789000000007')

    kimura.update!(times_url: 'https://discord.com/channels/715806612824260640/123456789000000007')

    visit current_path
    assert_link(href: 'https://discord.com/channels/715806612824260640/123456789000000007')
  end

  test 'show times link on user list page' do
    visit_with_auth '/users', 'hatsuno'
    assert_no_link(href: 'https://discord.com/channels/715806612824260640/123456789000000007')

    kimura = users(:kimura)
    kimura.update!(times_url: 'https://discord.com/channels/715806612824260640/123456789000000007')

    visit current_path
    assert_link(href: 'https://discord.com/channels/715806612824260640/123456789000000007')
  end

  test 'only admin can see link to talk on user list page' do
    visit_with_auth '/users', 'komagata'
    assert_link '相談部屋'
  end

  test 'not admin cannot see link to talk on user list page' do
    visit_with_auth '/users', 'kimura'
    assert_no_link '相談部屋'
  end

  test 'show daily report download button' do
    visit_with_auth "/users/#{users(:kimura).id}", 'komagata'
    assert_text '日報一括ダウンロード'
  end

  test 'not show daily report download button' do
    visit_with_auth "/users/#{users(:kimura).id}", 'hatsuno'
    assert_no_text '日報一括ダウンロード'
  end

  test 'show link to talk room when logined as admin' do
    kimura = users(:kimura)
    visit_with_auth "/users/#{kimura.id}", 'komagata'
    assert_text 'プロフィール'
    assert_link '相談部屋', href: "/talks/#{kimura.talk.id}"
  end

  test 'should not show link to talk room of admin even if logined as admin' do
    machida = users(:machida)
    visit_with_auth "/users/#{machida.id}", 'komagata'
    assert_text 'プロフィール'
    assert_no_link '相談部屋'
  end

  test 'should not show link to talk room when logined as no-admin' do
    hatsuno = users(:hatsuno)
    visit_with_auth "/users/#{hatsuno.id}", 'kimura'
    assert_text 'プロフィール'
    assert_no_link '相談部屋'
  end

  test 'show trainees for adviser' do
    visit_with_auth "/users/#{users(:kensyu).id}", 'senpai'
    assert_text '自社研修生'
    assert_no_text 'フォローする'
    assert_no_text '登録情報変更'
  end

  test 'show students' do
    visit_with_auth "/users/#{users(:kensyu).id}", 'hatsuno'
    assert_no_text '自社研修生'
    assert_text 'フォローする'
    assert_no_text '登録情報変更'
  end

  test 'show no trainees for adviser' do
    visit_with_auth "/users/#{users(:hatsuno).id}", 'senpai'
    assert_no_text '自社研修生'
    assert_text 'フォローする'
    assert_no_text '登録情報変更'
  end

  test 'show myself' do
    visit_with_auth "/users/#{users(:kensyu).id}", 'kensyu'
    assert_no_text '自社研修生'
    assert_no_text 'フォローする'
    assert_text '登録情報変更'
  end

  test 'show users trainees for adviser' do
    visit_with_auth '/users?target=trainee', 'senpai'
    assert_text '自社研修生'
  end

  test 'not show grass hide button for graduates' do
    visit_with_auth "/users/#{users(:sotugyou).id}", 'sotugyou'
    assert_not has_button? '非表示'
  end

  test 'show training end date if user is a trainee and has a training end date' do
    user = users(:kensyu)
    visit_with_auth user_path(user.id), 'kensyu'
    assert has_text?('研修終了日')
    assert has_text?('2022年04月01日')
  end

  test 'does not display training end date if user is a trainee and not has a training end date' do
    user = users(:kensyu)
    training_ends_on = nil
    visit_with_auth edit_admin_user_path(user.id), 'komagata'
    fill_in 'user_training_ends_on', with: training_ends_on
    click_on '更新する'
    visit_with_auth user_path(user.id), 'kensyu'
    assert has_no_field?('user_training_ends_on')
  end

  test 'if the number of days it took to graduate is positive, the value is displayed.' do
    user = users(:sotugyou)
    user.update!(created_at: Time.zone.today - 1, graduated_on: Time.zone.today, job: 'office_worker')
    visit_with_auth "/users/#{user.id}", 'sotugyou'
    assert_text '卒業 1日'
  end

  test 'if the number of days it took to graduate is negative, the value is not displayed.' do
    user = users(:sotugyou)
    user.update!(created_at: Time.zone.today, graduated_on: Time.zone.today - 1, job: 'office_worker')
    visit_with_auth "/users/#{user.id}", 'sotugyou'
    assert_no_text '卒業 1日'
  end

  test 'push guraduation button in user page when admin logined' do
    user = users(:kimura)
    visit_with_auth "/users/#{user.id}", 'komagata'
    accept_confirm do
      click_link '卒業にする'
    end
    assert_text '卒業済'
  end

  test 'change job seeking flag when click toggle button' do
    user = users(:hajime)
    visit_with_auth user_path(user.id), 'komagata'
    check '就職活動中', allow_label_click: true
    assert user.reload.job_seeking
  end

  test 'GET /users/new' do
    visit '/users/new'
    assert_equal 'フィヨルドブートキャンプ参加登録 | FJORD BOOT CAMP（フィヨルドブートキャンプ）', title
  end

  test 'incremental search by login_name' do
    visit_with_auth '/users', 'komagata'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: 'kimura'
    assert_text 'Kimura Tadasi', count: 1
  end

  test 'incremental search by name' do
    visit_with_auth '/users', 'kimura'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: 'Shinji'
    assert_text 'Hatsuno Shinji', count: 1
  end

  test 'incremental search by name_kana' do
    visit_with_auth '/users', 'mentormentaro'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: 'キムラ ミタイ'
    assert_text 'Kimura Mitai', count: 1
  end

  test 'incremental search by twitter_account' do
    visit_with_auth '/users', 'komagata'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: 'hatsuno'
    assert_text 'Hatsuno Shinji', count: 1
  end

  test 'incremental search by blog_url' do
    visit_with_auth '/users', 'komagata'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: 'hatsuno.org'
    assert_text 'Hatsuno Shinji', count: 1
  end

  test 'incremental search by github_account' do
    visit_with_auth '/users', 'komagata'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: 'kananashi'
    assert_text 'ユーザーです 読み方のカナが無い', count: 1
  end

  test 'incremental search by discord_account' do
    visit_with_auth '/users', 'komagata'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: 'kimura#1234'
    assert_text 'Kimura Tadasi', count: 1
  end

  test 'incremental search by facebook_url' do
    visit_with_auth '/users', 'komagata'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: 'kimurafacebook'
    assert_text 'Kimura Mitai', count: 1
  end

  test 'incremental search by description' do
    visit_with_auth '/users', 'komagata'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: '木村です'
    assert_text 'Kimura Tadasi', count: 1
  end

  test 'search only mentor when target is mentor' do
    visit_with_auth '/users?target=mentor', 'komagata'
    assert_equal 4, all('.users-item').length
    fill_in 'js-user-search-input', with: 'machida'
    assert_text 'Machida Teppei', count: 1

    fill_in 'js-user-search-input', with: 'kimura'
    assert_text '一致するユーザーはいません'
  end

  test 'search only graduated students when target is graduate' do
    visit_with_auth '/users?target=graduate', 'komagata'
    assert_equal 3, all('.users-item').length
    fill_in 'js-user-search-input', with: '卒業 就職済美'
    assert_text '卒業 就職済美', count: 1

    fill_in 'js-user-search-input', with: 'kimura'
    assert_text '一致するユーザーはいません'
  end

  test 'search only adviser when target is adviser' do
    visit_with_auth '/users?target=adviser', 'komagata'
    assert_equal 2, all('.users-item').length
    fill_in 'js-user-search-input', with: 'advijirou'
    assert_text 'アドバイ 次郎', count: 1

    fill_in 'js-user-search-input', with: 'kimura'
    assert_text '一致するユーザーはいません'
  end

  test 'search only trainee when target is trainee' do
    visit_with_auth '/users?target=trainee', 'komagata'
    assert_equal 2, all('.users-item').length
    fill_in 'js-user-search-input', with: 'Kensyu Seiko'
    assert_text 'Kensyu Seiko', count: 1

    fill_in 'js-user-search-input', with: 'kimura'
    assert_text '一致するユーザーはいません'
  end

  test 'search users from all users when target is all' do
    visit_with_auth '/users?target=all', 'komagata'
    assert_text 'ロード中'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: 'hajime'
    assert_text 'Hajime Tayo', count: 1

    fill_in 'js-user-search-input', with: 'machida'
    assert_text 'Machida Teppei', count: 1
  end

  test "don't show incremental search when target's users aren't exist" do
    visit_with_auth '/users?target=job_seeking', 'komagata'
    assert_equal 0, all('.users-item').length
    assert has_no_field? 'js-user-search-input'
  end

  test 'only show incremental search in all tab' do
    visit_with_auth '/users', 'komagata'
    assert has_field? 'js-user-search-input'

    visit '/generations'
    assert has_no_field? 'js-user-search-input'

    visit '/users/tags'
    assert has_no_field? 'js-user-search-input'

    visit '/users/tags/猫'
    assert has_no_field? 'js-user-search-input'

    visit '/users?target=followings'
    assert has_no_field? 'js-user-search-input'

    visit '/users/companies'
    assert has_no_field? 'js-user-search-input'
  end

  test 'incremental search needs more than two characters for Japanese and three for others' do
    visit_with_auth '/users', 'komagata'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: 'ki'
    assert_equal 20, all('.users-item').length
    fill_in 'js-user-search-input', with: 'kim'
    assert_text 'Kimura', count: 2

    fill_in 'js-user-search-input', with: 'キ'
    assert_selector '.user-list'
    assert_no_selector '.searched-user-list'
    fill_in 'js-user-search-input', with: 'キム'
    assert_text 'Kimura', count: 2
  end
end
