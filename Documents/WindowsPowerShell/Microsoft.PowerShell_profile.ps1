function open($str) {
	Start-Process $str
}

function execute($str) {
	iex($str)
}
