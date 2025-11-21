document.addEventListener("DOMContentLoaded", () => {
  const courseSelect = document.getElementById("course_id");
  const sectionSelect = document.getElementById("section_no");

  if (!courseSelect || !sectionSelect) {
    return;
  }

  let allSectionsData = [];
  try {
    allSectionsData = JSON.parse(sectionSelect.dataset.sections || "[]");
  } catch (err) {
    console.error("Failed to parse section data", err);
    allSectionsData = [];
  }

  const renderSections = () => {
    sectionSelect.innerHTML = '<option value="">-- Select a section --</option>';

    const selectedCourse = courseSelect.value;
    if (!selectedCourse) {
      return;
    }

    let sectionsAdded = 0;
    allSectionsData.forEach((sectionData) => {
      if (String(sectionData.courseId) === selectedCourse) {
        const openSeats =
          Number(sectionData.capacity) - Number(sectionData.num_enrolled);

        const newOption = document.createElement("option");
        newOption.value = sectionData.sectionNo;
        newOption.textContent = `Section ${sectionData.sectionNo} - ${
          sectionData.title || ""
        } (${openSeats} open seats)`;
        newOption.dataset.course = sectionData.courseId;
        newOption.dataset.capacity = sectionData.capacity;
        newOption.dataset.enrolled = sectionData.num_enrolled;
        sectionSelect.appendChild(newOption);
        sectionsAdded++;
      }
    });

    if (sectionsAdded === 0) {
      sectionSelect.innerHTML =
        '<option value="">-- No sections available for this course --</option>';
    }
  };

  courseSelect.addEventListener("change", renderSections);

  if (courseSelect.value) {
    renderSections();
  }
});
