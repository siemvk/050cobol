function activate() {
    let allLinks = document.querySelectorAll('weblink'); // Select <weblink> tags

    allLinks.forEach(element => {
        element.setAttribute('href', "javascript:goTo('" + element.getAttribute('href') + "')");
        changeTag(element, 'a');
    });

    let linkTriggers = document.querySelectorAll('linkTrigger'); // Select <weblink> tags

    linkTriggers.forEach(element => {
        let originalLink = element.getAttribute('js'); // Get the original link
        if (originalLink && originalLink !== "") {
            let aTag = document.createElement('a'); // Create a new <a> tag
            aTag.setAttribute('href', "javascript:eval('" + originalLink + "')"); // Set the href to JS function
            aTag.innerHTML = element.innerHTML; // Transfer inner content of <weblink> to <a>
    
            element.replaceWith(aTag); // Replace <weblink> with the new <a> tag
        }
    });


        
    let Triggers = document.querySelectorAll('trigger'); // Select <trigger> tags

    Triggers.forEach(element => {
        eval(element.innerHTML);
        element.remove();
    });
    


}
async function goTo(url) {
    const data = await makeRequest(url);
    if (checkElementExists('body')) {
        document.getElementById('body').innerHTML = data;
    } else {
        document.querySelector('webpage').innerHTML = data;
    }
    activate();

}
async function makeRequest(url) {
    try {
        const response = await fetch(url);
        if (!response.ok) {
            throw new Error('Network response was not ok ' + response.statusText);
        }
        const data = await response.text();
        return data;
    } catch (error) {
        console.error('Error:', error);
        return null;
    }
}


function checkElementExists(id) {
    var element = document.getElementById(id);
    if (element) {
        return true;
    } else {
        return false;
    }
}

function changeTag(element, newTagName) {
    if (!element) return null;

    // Create a new element with the desired tag
    const newElement = document.createElement(newTagName);

    // Copy the attributes from the old element to the new one
    [...element.attributes].forEach(attr => newElement.setAttribute(attr.name, attr.value));

    // Copy the content (if any)
    newElement.innerHTML = element.innerHTML;

    // Replace the old element with the new one
    element.parentNode.replaceChild(newElement, element);

    // Return the new element
    return newElement;
}