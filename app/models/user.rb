# == Schema Information
#
# Table name: users
#
#  id                :bigint           not null, primary key
#  activated         :boolean          default(FALSE)
#  activated_at      :datetime
#  activation_digest :string(255)
#  admin             :boolean          default(FALSE)
#  email             :string(255)
#  name              :string(255)
#  password_digest   :string(255)
#  remember_digest   :string(255)
#  reset_digest      :string(255)
#  reset_sent_at     :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#

class User < ApplicationRecord
  has_many :microposts, dependent: :destroy

  attr_accessor :remember_token, :activation_token, :reset_token
  before_save :downcase_email
  before_create :create_activation_digest


  #ユーザー登録でemailを小文字に変換してdbに保存
  before_save {self.email = self.email.downcase}

  validates :name, presence: true, length: {maximum: 50}

  #メールアドレスチェックの正規表現
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: {maximum: 255}, format: {with: VALID_EMAIL_REGEX}, uniqueness: {case_sensitive: false}

  #has_secure_passwordメソッドの呼び出し
  has_secure_password

  # has_secure_passwordによって自動的に追加された属性passwordのバリデーション
  # allow_nil: true は空の場合はバリデーションをしないが
  # has_secure_passwordではオブジェクト生成時のみ存在性を検証するようになっているので
  # 空のパスワード (nil) が新規ユーザー登録時に有効になることはない
  validates :password, presence: true, length: {minimum: 6}, allow_nil: true


  # 渡された文字列のハッシュ値を返す
  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
               BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを返す
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # 永続セッションのためにユーザーをデータベースに記憶する
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # トークンがダイジェストと一致したらtrueを返す
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # ユーザーのログイン情報を破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end

  # アカウントを有効にする
  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  # 有効化用のメールを送信する
  def send_activation_email
    Manage::UserMailer.account_activation(self).deliver_now
  end

  # パスワードの再設定の属性を設定する
  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest:  User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  # パスワードの再設定のメールを送信する
  def send_password_reset_email
    Manage::UserMailer.password_reset(self).deliver_now
  end

  # パスワード再設定の期限が切れている場合はtrueを返す
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  private


  # before_save

  # メールアドレスを全て小文字にする
  def downcase_email
    self.email = email.downcase
  end

  # before_create

  # 有効化トークンとダイジェストを作成および代入する
  def create_activation_digest
    self.activation_token = User.new_token
    self.activation_digest = User.digest(activation_token)
  end

end
