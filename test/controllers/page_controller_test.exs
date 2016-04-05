defmodule Magpie.PageControllerTest do
  use Magpie.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Hello Magpie!"
  end
end
