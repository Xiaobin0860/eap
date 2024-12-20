
�.
ClientGate.proto
ClientGate"�
LoginRequest-

login_type (2.ClientGate.EnumLoginType
account (	
password (	
nick (	&
gender (2.ClientGate.EnumGender/
device_type (2.ClientGate.EnumDeviceType
	device_id (	
device_token (	
mac	 (	

secure_key
 (	
channel (	
version (
phone_no (	"�
BasicUserInfo
user_id (	
nick (	
avatar (	&
gender (2.ClientGate.EnumGender

user_score (
lev (

experience (
vip (
activity	 ("�
LoginResponse&
result (2.ClientGate.EnumResult2
basic_user_info (2.ClientGate.BasicUserInfo

update_url (	
ios_update_url (	
latest_version (	
update_info (	".
GetOnlineUsers
start (
count (":
OnlineUserList(
users (2.ClientGate.BasicUserInfo"M
AddFriendReqest
	target_id (	'
user (2.ClientGate.BasicUserInfo"e
AddFriendConfirm
	target_id (	
result (.
target_user (2.ClientGate.BasicUserInfo"?
ClientGetInstanceListRequest
	game_name (	
type ("$
ClientGetUserInfo
user_id (	"O
ClientGetUserInfoResponse2
basic_user_info (2.ClientGate.BasicUserInfo"U
EnterGameRequest
	game_name (	
room_id (
desc (	
seat_id ("*
QuickEnterGameRequest
	game_name (	"�
UserTableInfo
Uid (	
Money (
Index (
OwnCard (
SidePool (
CurBet (
TotalBet (
Flod (
AllIn	 (
	InGameing
 ("l
TableUserInfo,
	user_base (2.ClientGate.BasicUserInfo-

user_table (2.ClientGate.UserTableInfo"(
SidePool
index (
money ("�
	TableInfo
Gameing (
ButtonPlayer (
SmallPlayer (
	BigPlayer (
	DownCards (
	CurMaxBet (
Pot (
	CurPlayer ('
	side_pool	 (2.ClientGate.SidePool
	main_pool
 (
timer (
small_money (
	big_money ("�
EnterGameResponse&
result (2.ClientGate.EnumResult,
why (2.ClientGate.EnumEnterGameResult)

table_info (2.ClientGate.TableInfo,
	user_info (2.ClientGate.TableUserInfo"n
OtherEnterGameResponse&
result (2.ClientGate.EnumResult,
	user_info (2.ClientGate.TableUserInfo"
LeaveGameRequest"!
OtherLeaveGame
user_id (	"!
UserDisconnect
user_id (	"=
	LookTable
	game_name (	
room_id (
desc (	"�
LookTableResponse&
result (2.ClientGate.EnumResult)

table_info (2.ClientGate.TableInfo,
	user_info (2.ClientGate.TableUserInfo"�

DealToUser
card_a (
card_b (
button_user_id (	
small_user_id (	
big_user_id (	
start_user_id (	
small_stakes (

big_stakes ("+
OnePoolInfo
index (
money ("E
SidePool_New
index (&
pools (2.ClientGate.OnePoolInfo"6
MainPool_New&
pools (2.ClientGate.OnePoolInfo"�

CardToUser
start_user_id (	
card (+
	main_pool (2.ClientGate.MainPool_New+
	side_pool (2.ClientGate.SidePool_New"

UserFold"�
UserFlodResponse&
result (2.ClientGate.EnumResult
next_user_id (	
cur_round_total_bet (
cur_round_max_raise ("p
OtherUserFlod
user_id (	
next_user_id (	
cur_round_total_bet (
cur_round_max_raise ("

UserCall"�
UserCallResponse&
result (2.ClientGate.EnumResult
money (
next_user_id (	
cur_round_total_bet (
cur_round_max_raise ("
OtherUserCall
user_id (	
money (
next_user_id (	
cur_round_total_bet (
cur_round_max_raise ("
	UserRaise
multi ("�
UserRaiseResponse&
result (2.ClientGate.EnumResult
money (
next_user_id (	
cur_round_total_bet (
cur_round_max_raise ("�
OtherUserRaise
user_id (	
money (
next_user_id (	
cur_round_total_bet (
cur_round_max_raise ("-
Key32ValueArray
key (
cards ("*
Key32Value32
key (
value ("v
SettleUserInfo
index (
money (

card_level (
win_flag (
cards (
	own_cards ("�
PoolMoneyToUser&
main (2.ClientGate.MainPool_New&
side (2.ClientGate.SidePool_New(
return (2.ClientGate.MainPool_New"�
SettleToUser(
info (2.ClientGate.SettleUserInfo+
	main_pool (2.ClientGate.MainPool_New+
	side_pool (2.ClientGate.SidePool_New6
distribution_info (2.ClientGate.PoolMoneyToUser

down_cards ("3
UseItem
other_user_id (	
	item_type ("c
UseItemResponse&
result (2.ClientGate.EnumResult
other_user_id (	
	item_type ("I
OtherUseItem
user_id (	
other_user_id (	
	item_type ("/
UpdateFriend
	friend_id (	
flag ("
OpenBox
box_type ("L
OpenBoxResponse&
result (2.ClientGate.EnumResult
	add_money (".
AddMoneyInfo
user_id (
money ("=
AddTableMoney,

money_info (2.ClientGate.AddMoneyInfo*r
EnumLoginType 
enumLoginTypeRegisterNewUser 
enumLoginTypeGuestAccount 
enumLoginTypeRegisterAccount*M

EnumGender
enumGenderFemale 
enumGenderMale
enumGenderUnknown*x
EnumDeviceType
enumDeviceTypeiPhone 
enumDeviceTypeiPad
enumDeviceTypeAndroid
enumDeviceTypeWindows*4

EnumResult
enumResultSucc 
enumResultFail*~
EnumNewVersion
enumUpdateTipNoNewVersion 
enumUpdateTipHasNewVersion-
)enumUpdateTipHasNewVersionMandatoryUpdate*�
EnumVIPLevel
enumVIPLevelNone 
enumVIPLevelSilver
enumVIPLevelGold
enumVIPLevelPlatinum
enumVIPLevelDiamond*?
EnumAddFriendResult
Refused 
Accepted
	NotOnline*�
EnumEnterGameResult
NO_SUCH_GAME���������
NO_SUCH_INSTANCE���������
NOT_ENOUGH_MONEY��������� 
SERVER_CONFIG_ERROR���������
UNKNOWN_ERROR���������"
MAX_ENTER_GAME_RESULT���������BH