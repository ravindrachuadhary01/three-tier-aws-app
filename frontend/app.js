const API_URL = "http://app-alb-314069837.ap-south-1.elb.amazonaws.com";

// -------------------------
// ADD USER (POST)
// -------------------------
async function addUser() {
    const name = document.getElementById("name").value;
    const email = document.getElementById("email").value;

    if (!name || !email) {
        alert("Please enter name and email");
        return;
    }

    try {
        const response = await fetch(`${API_URL}/add-user`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                name: name,
                email: email
            })
        });

        const data = await response.json();
        console.log(data);

        alert("User added successfully!");

        document.getElementById("name").value = "";
        document.getElementById("email").value = "";

        getUsers(); // auto refresh list

    } catch (error) {
        console.error("Error:", error);
        alert("Backend not reachable!");
    }
}

// -------------------------
// GET USERS (GET)
// -------------------------
async function getUsers() {
    try {
        const response = await fetch(`${API_URL}/users`);
        const data = await response.json();

        console.log(data);

        document.getElementById("output").innerText =
            JSON.stringify(data, null, 2);

    } catch (error) {
        console.error("Error:", error);
        document.getElementById("output").innerText =
            "Error connecting to backend";
    }
}