
# simple tests for the rust id reference resolution
# to run this, simply run the nix stuff (readme) and then run this script.
# it'll add two systems and run various checks to make sure, the output is correct

nix --extra-experimental-features flakes --extra-experimental-features nix-command develop .#services -c psql "postgresql://postgres@localhost:5432/pluralkit" -c "

-- system 1
DELETE FROM system_config WHERE system = (SELECT id FROM systems WHERE hid = 'aaaaaa');
DELETE FROM accounts where system = (SELECT id FROM systems WHERE hid = 'aaaaaa');
DELETE FROM systems WHERE hid = 'aaaaaa';

INSERT INTO systems (id, hid, name, token) VALUES (1, 'aaaaaa', 'Test System', 'pk_test_dev_token');
INSERT INTO system_config (system) VALUES ((SELECT id FROM systems WHERE hid = 'aaaaaa'));
INSERT INTO accounts (uid, system) VALUES (502894289114628110, (SELECT id FROM systems WHERE hid = 'aaaaaa'));
INSERT INTO members (id, hid, system, name) VALUES (10, 'aaa10', 1, 'aaa10');
INSERT INTO members (id, hid, system, name) VALUES (11, 'aaa11', 1, 'aaa11');

DELETE FROM switch_members WHERE switch IN (SELECT id FROM switches WHERE system = 1);
DELETE FROM switches WHERE system = 1;
INSERT INTO switches (id, system, timestamp) VALUES (1000, 1, NOW());
INSERT INTO switch_members (id, switch, member) VALUES (10000, 1000, 10);
INSERT INTO switch_members (id, switch, member) VALUES (10001, 1000, 11);
INSERT INTO switches (id, system, timestamp) VALUES (1001, 1, NOW() - INTERVAL '1 hour');
INSERT INTO switch_members (id, switch, member) VALUES (10002, 1001, 10);

INSERT INTO groups (hid, system, name) VALUES ('grp11', 1, 'grp11');
INSERT INTO groups (hid, system, name) VALUES ('grp12', 1, 'grp12');


-- system 2
DELETE FROM system_config WHERE system = (SELECT id FROM systems WHERE hid = 'bbbbbb');
DELETE FROM accounts where system = (SELECT id FROM systems WHERE hid = 'bbbbbb');
DELETE FROM systems WHERE hid = 'bbbbbb';

INSERT INTO systems (id, hid, name, token) VALUES (2, 'bbbbbb', 'Test System 2', 'pk_test_dev_token_2');
INSERT INTO system_config (system) VALUES ((SELECT id FROM systems WHERE hid = 'bbbbbb'));
INSERT INTO accounts (uid, system) VALUES (502894289114628111, (SELECT id FROM systems WHERE hid = 'bbbbbb'));
INSERT INTO members (id, hid, system, name) VALUES (20, 'bbb20', 2, 'bbb20');
INSERT INTO members (id, hid, system, name) VALUES (21, 'bbb21', 2, 'bbb21');

DELETE FROM switch_members WHERE switch IN (SELECT id FROM switches WHERE system = 2);
DELETE FROM switches WHERE system = 2;
INSERT INTO switches (id, system, timestamp) VALUES (2000, 2, NOW());
INSERT INTO switch_members (id, switch, member) VALUES (20000, 2000, 20);

INSERT INTO groups (hid, system, name) VALUES ('grp21', 2, 'grp21');
INSERT INTO groups (hid, system, name) VALUES ('grp22', 2, 'grp22');
"


extract_from_query() {
    QUERY="$1"
    nix --extra-experimental-features flakes --extra-experimental-features nix-command develop .#services \
        -c psql "postgresql://postgres@localhost:5432/pluralkit" \
        -c "$QUERY" | sed '3q;d' | awk '{$1=$1};1'
}
export -f extract_from_query

UUID1="$( extract_from_query "SELECT uuid FROM systems WHERE hid = 'aaaaaa';" )"

MEM10="$( extract_from_query "SELECT uuid FROM members WHERE hid = 'aaa10';" )"

MEM11="$( extract_from_query "SELECT uuid FROM members WHERE hid = 'aaa11';" )"

UUID2="$( extract_from_query "SELECT uuid FROM systems WHERE hid = 'bbbbbb';" )"

MEM20="$( extract_from_query "SELECT uuid FROM members WHERE hid = 'bbb20';" )"

MEM21="$( extract_from_query "SELECT uuid FROM members WHERE hid = 'bbb21';" )"

GRP11="$( extract_from_query "SELECT uuid FROM groups WHERE hid = 'grp11';" )"

GRP12="$( extract_from_query "SELECT uuid FROM groups WHERE hid = 'grp12';" )"

GRP21="$( extract_from_query "SELECT uuid FROM groups WHERE hid = 'grp21';" )"

GRP22="$( extract_from_query "SELECT uuid FROM groups WHERE hid = 'grp22';" )"

GRP11_ID="$( extract_from_query "SELECT id FROM groups WHERE hid = 'grp11';" )"

GRP12_ID="$( extract_from_query "SELECT id FROM groups WHERE hid = 'grp12';" )"

GRP21_ID="$( extract_from_query "SELECT id FROM groups WHERE hid = 'grp21';" )"

GRP22_ID="$( extract_from_query "SELECT id FROM groups WHERE hid = 'grp22';" )"

SW1000="$( extract_from_query "SELECT uuid FROM switches WHERE id = 1000;" )"

SW1001="$( extract_from_query "SELECT uuid FROM switches WHERE id = 1001;" )"

SW2000="$( extract_from_query "SELECT uuid FROM switches WHERE id = 2000;" )"



check(){
    L="$1"
    CMP="$2"
    R="$3"

    if eval "[[ '$L' $CMP '$R' ]]" ; then
        echo "✅ $L $CMP $R"
    else
        echo "❌ $L $CMP $R"
    fi
}





check "$(curl -s http://localhost:5001/v2/systems/aaaaaa 2>&1)" == "Some(RequestAboutSystem { id: 1 }) None None None | None"

check "$(curl -s http://localhost:5001/v2/systems/$UUID1 2>&1)" == 'Some(RequestAboutSystem { id: 1 }) None None None | None'

check "$(curl -s http://localhost:5001/v2/systems/502894289114628110 2>&1)" == 'Some(RequestAboutSystem { id: 1 }) None None None | None'



check "$(curl -s http://localhost:5001/v2/members/aaa10 2>&1)" == "Some(RequestAboutSystem { id: 1 }) Some(RequestAboutMember { id: 10, system: 1 }) None None | None"

check "$(curl -s http://localhost:5001/v2/members/aaa11 2>&1)" == 'Some(RequestAboutSystem { id: 1 }) Some(RequestAboutMember { id: 11, system: 1 }) None None | None'

check "$(curl -s http://localhost:5001/v2/members/$MEM10 2>&1)" == "Some(RequestAboutSystem { id: 1 }) Some(RequestAboutMember { id: 10, system: 1 }) None None | None"

check "$(curl -s http://localhost:5001/v2/members/$MEM11 2>&1)" == 'Some(RequestAboutSystem { id: 1 }) Some(RequestAboutMember { id: 11, system: 1 }) None None | None'



check "$(curl -s http://localhost:5001/v2/groups/grp11 2>&1)" == "Some(RequestAboutSystem { id: 1 }) None Some(RequestAboutGroup { id: $GRP11_ID, system: 1 }) None | None"

check "$(curl -s http://localhost:5001/v2/groups/$GRP11 2>&1)" == "Some(RequestAboutSystem { id: 1 }) None Some(RequestAboutGroup { id: $GRP11_ID, system: 1 }) None | None"

check "$(curl -s http://localhost:5001/v2/groups/grp12 2>&1)" == "Some(RequestAboutSystem { id: 1 }) None Some(RequestAboutGroup { id: $GRP12_ID, system: 1 }) None | None"

check "$(curl -s http://localhost:5001/v2/groups/$GRP12 2>&1)" == "Some(RequestAboutSystem { id: 1 }) None Some(RequestAboutGroup { id: $GRP12_ID, system: 1 }) None | None"



check "$(curl -s http://localhost:5001/v2/systems/bbbbbb 2>&1)" == "Some(RequestAboutSystem { id: 2 }) None None None | None"

check "$(curl -s http://localhost:5001/v2/systems/$UUID2 2>&1)" == 'Some(RequestAboutSystem { id: 2 }) None None None | None'

check "$(curl -s http://localhost:5001/v2/systems/502894289114628111 2>&1)" == 'Some(RequestAboutSystem { id: 2 }) None None None | None'



check "$(curl -s http://localhost:5001/v2/systems/aaaaaa/switches/$SW1000 2>&1)" == "Some(RequestAboutSystem { id: 1 }) None None Some(RequestAboutSwitch { id: 1000, system: 1 }) | None"

check "$(curl -s http://localhost:5001/v2/systems/aaaaaa/switches/$SW1001 2>&1)" == 'Some(RequestAboutSystem { id: 1 }) None None Some(RequestAboutSwitch { id: 1001, system: 1 }) | None'

check "$(curl -s http://localhost:5001/v2/systems/bbbbbb/switches/$SW2000 2>&1)" == "Some(RequestAboutSystem { id: 2 }) None None Some(RequestAboutSwitch { id: 2000, system: 2 }) | None"



check "$(curl -s http://localhost:5001/v2/groups/grp21 2>&1)" == "Some(RequestAboutSystem { id: 2 }) None Some(RequestAboutGroup { id: $GRP21_ID, system: 2 }) None | None"

check "$(curl -s http://localhost:5001/v2/groups/$GRP21 2>&1)" == "Some(RequestAboutSystem { id: 2 }) None Some(RequestAboutGroup { id: $GRP21_ID, system: 2 }) None | None"

check "$(curl -s http://localhost:5001/v2/groups/grp22 2>&1)" == "Some(RequestAboutSystem { id: 2 }) None Some(RequestAboutGroup { id: $GRP22_ID, system: 2 }) None | None"

check "$(curl -s http://localhost:5001/v2/groups/$GRP22 2>&1)" == "Some(RequestAboutSystem { id: 2 }) None Some(RequestAboutGroup { id: $GRP22_ID, system: 2 }) None | None"



check "$(curl -s -H 'Authorization: pk_test_dev_token' http://localhost:5001/v2/systems/@me 2>&1)" == 'Some(RequestAboutSystem { id: 1 }) None None None | Some(1)'

check "$(curl -s -H 'Authorization: pk_test_dev_token_2' http://localhost:5001/v2/systems/@me 2>&1)" == 'Some(RequestAboutSystem { id: 2 }) None None None | Some(2)'

check "$(curl -s http://localhost:5001/v2/systems/@me 2>&1)" == '{"message":"401: Missing or invalid Authorization header","code": 0}'

check "$(curl -s -H 'Authorization: invalid_token' http://localhost:5001/v2/systems/@me 2>&1)" == '{"message":"401: Missing or invalid Authorization header","code": 0}'

check "$(curl -s -H 'Authorization: pk_test_dev_token' http://localhost:5001/v2/systems/bbbbbb 2>&1)" == 'Some(RequestAboutSystem { id: 2 }) None None None | Some(1)'

check "$(curl -s -H 'Authorization: pk_test_dev_token_2' http://localhost:5001/v2/members/aaa10 2>&1)" == 'Some(RequestAboutSystem { id: 1 }) Some(RequestAboutMember { id: 10, system: 1 }) None None | Some(2)'



check "$(curl -s http://localhost:5001/v2/systems/nonexistent 2>&1)" == '{"message":"System not found.","code":20001}'

check "$(curl -s http://localhost:5001/v2/members/nonexistent 2>&1)" == '{"message":"Member not found.","code":20002}'

check "$(curl -s http://localhost:5001/v2/groups/nonexistent 2>&1)" == '{"message":"Group not found.","code":20004}'

