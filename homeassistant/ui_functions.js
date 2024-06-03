// This will delete all devices of a particular model type.  Run this from the developer console in Chrome.

async function deleteDevices(model_to_delete) {
    let hass = document.querySelector("home-assistant").hass;
    let message = { type: "config/device_registry/list" };
    let count = 0;

    await hass.callWS(message).then(async(response) => {
        for (let i = 0; i < response.length; i++) {
            device = response[i];
            if (device["model"] === model_to_delete) {
                await hass.callWS({
                    "type":"config/device_registry/remove_config_entry",
                    "device_id": device["id"],
                    "config_entry_id": device["config_entries"][0],
                }).then((response) => {
                    console.log(`Deleted device ${JSON.stringify(device)}`);
                    count++;
                })
            }
        }
        console.log(`Deleted ${count} devices`);
    })
}
