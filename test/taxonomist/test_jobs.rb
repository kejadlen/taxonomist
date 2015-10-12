require_relative "../test_helper"
require_relative "../karate_club"

require "taxonomist/jobs"

class TestJob < Test
  def setup
    without_warnings do
      @original_twitter_adapter = Jobs::Job::TWITTER_ADAPTER
      Jobs::Job.const_set(:TWITTER_ADAPTER, KarateClub)
    end

    @user = Models::User.create(twitter_id: 1)
    @karate_club = KarateClub.new
  end

  def teardown
    without_warnings do
      Jobs::Job.const_set(:TWITTER_ADAPTER, @original_twitter_adapter)
    end
  end
end

class TestUpdateUser < TestJob
  def test_update_user
    Jobs::UpdateUser.enqueue(@user.id)

    @user.refresh

    twitter_id = @user.twitter_id
    assert_equal({'id' => twitter_id,
                  'screen_name' => KarateClub::SCREEN_NAMES[twitter_id]},
                 @user.raw)
    assert_equal KarateClub::FRIENDS[@user.twitter_id], @user.friend_ids
  end
end

class TestHydrateFriends < TestJob
  class LimitedHydrateFriends < Jobs::HydrateFriends
    def users_per_request
      2
    end
  end

  def test_nonexistent_friends
    friends = KarateClub::FRIENDS[@user.twitter_id]
    Jobs::HydrateFriends.enqueue(@user.id, friends)

    friends.each do |friend|
      assert_equal Models::User[twitter_id: friend].raw["screen_name"],
                   KarateClub::SCREEN_NAMES[friend]
    end
  end

  def test_existing_friends
    friend_ids = KarateClub::FRIENDS[@user.twitter_id]
    friend_ids.each do |id|
      Models::User.create(twitter_id: id)
    end

    Jobs::HydrateFriends.enqueue(@user.id, friend_ids)

    friend_ids.each do |id|
      assert_equal Models::User[twitter_id: id].raw["screen_name"],
                   KarateClub::SCREEN_NAMES[id]
    end
  end

  def test_existing_and_nonexistent_friends
    friend_ids = KarateClub::FRIENDS[@user.twitter_id]
    Models::User.create(twitter_id: friend_ids.first)

    Jobs::HydrateFriends.enqueue(@user.id, friend_ids)

    friend_ids.each do |id|
      assert_equal Models::User[twitter_id: id].raw["screen_name"],
                   KarateClub::SCREEN_NAMES[id]
    end
  end

  def test_users_per_request
    friend_ids = KarateClub::FRIENDS[@user.twitter_id]
    LimitedHydrateFriends.enqueue(@user.id, friend_ids)

    friend_ids.each do |id|
      assert_equal Models::User[twitter_id: id].raw["screen_name"],
                   KarateClub::SCREEN_NAMES[id]
    end
  end
end
