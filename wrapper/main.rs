#[macro_use]
extern crate rocket;

use rocket::response::status;

#[delete("/<id>?<user>")]
fn delete(id: i32, user: i32) -> status::SeeOther {
	status::SeeOther
}