i am creating mitmproxy ui, for filtering i need to create ui in flutter.

mitm proxy supports advance filtering:

~aMatch asset in response: CSS, JavaScript, images, fonts.
~allMatch all flows
~b regex Body
~bq regex Request body
~bs regex Response body
~c int HTTP response code
~comment regex Flow comment
~d regex Domain
~dnsMatch DNS flows
~dst regex Match destination address
~e Match error
~h regex Header
~hq regex Request header
~hs regex Response header
~httpMatch HTTP flows
~m regex Method
~marked Match marked flows
~marker regex Match marked flows with specified marker
~meta regex Flow metadata
~qMatch request with no response
~replay Match replayed flows
~replay qMatch replayed client request
~replays Match replayed server response
~s Match response
~src regex Match source address
~t regex Content-type header
~tcpMatch TCP flows
~tq regex Request Content-Type header
~ts regex Response Content-Type header
~u regex URL
~udp Match UDP flows
~websocket Match WebSocket flows
! unary not
& and
| or
(...) grouping

because it supports grouping , it supports nest expresions like ( ( ... & ... ) | ! ( ... & ) )

so in my ui i decided instead of plain test type input, i use selectors and blocks.

- | key | value | +
- if we select key it shows all keys like url,requestUrl,....
- if we select value enter value for that key
- on center border of key | value border we add symbol `~` it means `regex` by default it has `~`
- if we click on `~` it shows menu to choose `starts with`,`ends with`, `equals`, `regex`. and their respective symbols like `^`, `$`, `=`, `~` are shows in the center border. and also in the menu it shows wrap with block and nested block option for nested expression ( ~u hi & (~s 300 ) )
- also when we press `+` it add another row as next to it , and asks to choose `&`, `|`. it creates a block right to it.ex; (~u hi) | (~s 300)
- and also when we click center border operator `~` ,it shows negation operator `!` when we click it shows negation operator before the block (not at the center), note selecting negation operator or wrap with block and nest block will not effect the current block operator which shows in the center border.

- note all these are no need to convert to mitmproxy string filter expression, instead it will be in a forward that will be used to filter dart List<MitmFlow>.
- when i click on key, it show all suggestion , in scrollable list (because there are many keys) and also input at start of to easily filter the keys

- u must need to implement grouping feature ( not placeholder, real working feature required)
  u provided wrap with group and nested group at right side menu, don't do that instead add merge them in center operator, on right add plus btn to pick & or |
  don't use bottom drawer for picker instead a popup style widget pick at the input place.
  its for desktop not for android , the way u give is very large
  don't use any tex colors, make inputs small
