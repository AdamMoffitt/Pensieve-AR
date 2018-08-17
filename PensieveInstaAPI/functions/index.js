const functions = require('firebase-functions');
var XMLHttpRequest = require("xmlhttprequest").XMLHttpRequest;
var async = require("async");

// Token for Instagram API
var TOKEN = "39718128.c4f14f3.ee4a52652d094149ac816148a1f12be2";

// https://stackoverflow.com/questions/9229645/remove-duplicate-values-from-js-array
function uniq(a) {
    var seen = {};
    return a.filter(function(item) {
        return seen.hasOwnProperty(item) ? false : (seen[item] = true);
    });
}

// Returns a Promise(HTML page from URL)
function fetchRequest(url) {
    return new Promise((resolve, reject) => {
	const xhr = new XMLHttpRequest();
	xhr.open("GET", url, true);
	xhr.onload = () => resolve(xhr.responseText);
	xhr.onerror = () => reject("AAAAHHHHHHAHAHAHAHA");
	xhr.send();
    });
}

// Returns a Promise(closest Insta Location ID to Coordinates)
function fetchInstaLocations(latitude = "34.411640", longitude = "-119.847060") {
    api = `https://api.instagram.com/v1/locations/search?lat=${latitude}&lng=${longitude}&access_token=${TOKEN}`;
    console.log(api);
    return new Promise((resolve, reject) => {
	fetchRequest(api).then((data) => {
	    resolve(JSON.parse(data)['data'][0]['id'])
	});
    });
}

// Returns a Promise(10 recent images to a locationID)
function fetchInstaImages(locationID = "212956468", n = 10) {
    api = `https://www.instagram.com/explore/locations/${locationID}/`;
    console.log(api);
    return new Promise((resolve, reject) => {
	fetchRequest(api).then(
	    (html) => {
		var location_images = html.split(" ").filter(str => str.includes("cdninstagram")&&str.includes("640")).map(url => (url.replace("content=", "").replace(".jpg", ".jpg,").split(",")[0]).replace('"',""));
		resolve(uniq(location_images).splice(0,n-1));
	    });
    });
}

function scrapeInstagramLocation(locationID = "212956468", n = 10) {
    var api = `https://www.instagram.com/explore/locations/${locationID}/`;
    return new Promise((resolve, reject) => {
	fetchRequest(api).then((html) => {
	    var raw_json = html.split("window._sharedData = ")[1].split(";</script>")[0];
	    var json = JSON.parse(raw_json);
	    var location = json["entry_data"]["LocationsPage"][0]["location"]; 
	    var posts = location["top_posts"]["nodes"];
	    var locationID = location["id"];
	    
	    var post_data = [];
	    
	    var i = 0;
	    async.each(posts, (post, callback) => {
		var new_post = {}
		
		new_post["is_video"] = post["is_video"];
		new_post["caption"] = post["caption"];
		new_post["likes"] = post["likes"]["count"];
		new_post["src"] = post["display_src"];
	    
		if (new_post["is_video"]) {
		    var videoID = post["code"];
		    var video_api = `https://www.instagram.com/p/${videoID}/?taken-at=${locationID}`;
		    fetchRequest(video_api).then((html) => {
			var video = html.split("video_url\":")[1].replace("mp4", "mp4,").split(",")[0].replace(' "',"");
			new_post["src"] = video;
			post_data.push(new_post);
			callback();
		    });
		} else {
		    post_data.push(new_post);
		    callback();
		}
	    
	    }, (err) => {
		if (err) {
		    reject("Error getting img/videos");
		} else {
		    resolve(post_data.slice(0, n));
		}
	    });
	});
    });
}

function scrapeInstagramProfile(profile="ucsantabarbara", n = 10) {
    var api = `https://www.instagram.com/${profile}`;
    return new Promise((resolve, reject) => {
		fetchRequest(api).then((html) => {
		    var raw_json = html.split("window._sharedData = ")[1].split(";</script>")[0];
		    var json = JSON.parse(raw_json);
		    var user = json["entry_data"]["ProfilePage"][0]["graphql"]["user"];
		    // console.log(json["entry_data"]["ProfilePage"][0]["graphql"]["user"]);
		    // console.log(json);
		    // console.log(user["edge_owner_to_timeline_media"]);
		    var posts = user["edge_owner_to_timeline_media"]["edges"];
		    
		    var post_data = [];
		    
		    var i = 0;
			async.each(posts, (post, callback) => {
				var new_post = {}
				// console.log(post)
				post = post["node"];
				console.log(post["edge_media_to_caption"]["edges"][0]["node"]["text"])
				new_post["is_video"] = post["is_video"];
				new_post["caption"] = post["edge_media_to_caption"]["edges"][0]["node"]["text"];
				new_post["likes"] = post["edge_liked_by"]["count"];
				new_post["src"] = post["thumbnail_src"];
			    
				if (new_post["is_video"]) {
				    var videoID = post["shortcode"];
				    var video_api = `https://www.instagram.com/p/${videoID}`;
				    fetchRequest(video_api).then((html) => {
				    	console.log("************************")
				    	console.log(video_api)
				    	var raw_json = html.split("window._sharedData = ")[1].split(";</script>")[0];
						console.log(raw_json)
				    	console.log("************************")
						
						// var video = html.split("video_url\":")[0].replace("mp4", "mp4,").split(",")[0].replace(' "',"");
						var json = JSON.parse(raw_json)
						var video = json["entry_data"]["PostPage"][0]["graphql"]["shortcode_media"]["video_url"]
						console.log(video);
						new_post["src"] = video;
						post_data.push(new_post);
						callback();
				    });
				} else {
				    post_data.push(new_post);
				    callback();
				}
			    
			}, (err) => {
				if (err) {
				    reject("Error getting img/videos");
				} else {
				    resolve(post_data.slice(0, n));
				}
		    });
		});
    });
}


exports.instaImages = functions.https.onRequest((req, res) => {
    var lat = null;
    var lon = null;

    try {
	lat = req.query.latitude.toString();
	console.log(lat);
	lon = req.query.longitude.toString();
	console.log(lon);
    } catch (err) {
	console.log("Parameters not passed in properly");
	res.status(400).send();
	return;
    }
    
    if (lat !== null && lon !== null) {
	fetchInstaLocations(lat, lon).then( (locationID) => {
	    fetchInstaImages(locationID).then((insta_posts) => {
		// [START_EXCLUDE silent]
		// [START cachecontrol]
		res.set('Cache-Control', 'public, max-age=300, s-maxage=600');
		// [END cachecontrol]
		// [START vary]
		res.set('Vary', 'Accept-Encoding, X-My-Custom-Header');
		// [END vary]
		// [END_EXCLUDE]
		console.log(insta_posts);
		res.status(200).send(JSON.stringify(insta_posts));
	    });
	});
    } else {
	res.status(400).send();
    }
});


exports.instagramLocationScraper = functions.https.onRequest((req, res) => {
    var lat = null;
    var lon = null;

    try {
	lat = req.query.latitude.toString();
	console.log(lat);
	lon = req.query.longitude.toString();
	console.log(lon);
    } catch (err) {
	console.log("Parameters not passed in properly");
	res.status(400).send();
	return;
    }
    
    if (lat !== null && lon !== null) {
	fetchInstaLocations(lat, lon).then( (locationID) => {
	    scrapeInstagramLocation(locationID).then((insta_posts) => {
		// [START_EXCLUDE silent]
		// [START cachecontrol]
		res.set('Cache-Control', 'public, max-age=300, s-maxage=600');
		// [END cachecontrol]
		// [START vary]
		res.set('Vary', 'Accept-Encoding, X-My-Custom-Header');
		// [END vary]
		// [END_EXCLUDE]
		console.log(insta_posts);
		res.status(200).send(JSON.stringify(insta_posts));
	    });
	});
    } else {
	res.status(400).send();
    }
});

exports.instagramProfileScraper = functions.https.onRequest((req, res) => {
    var profile = null;
    var n = 10;

    try {
		profile = req.query.profile;
		if (req.query.n !== '') {
		    n = req.query.n;
		    console.log(n);
		}
    } catch (err) {
		console.log("Parameters not passed in properly");
		res.status(400).send();
		return;
    }
    
    if (profile !== null) {
	scrapeInstagramProfile(profile, n).then((insta_posts) => {
	    // [START_EXCLUDE silent]
	    // [START cachecontrol]
	    res.set('Cache-Control', 'public, max-age=300, s-maxage=600');
	    // [END cachecontrol]
	    // [START vary]
	    res.set('Vary', 'Accept-Encoding, X-My-Custom-Header');
	    // [END vary]
	    // [END_EXCLUDE]
	    console.log(insta_posts);
	    res.status(200).send(JSON.stringify(insta_posts));
	});
    } else {
	res.status(400).send();
    }
});

scrapeInstagramProfile();//.then( (d) => console.log(d));
