/* BEGIN EXTERNAL SOURCE */

        // Xử lý tab tìm kiếm
        const tabs = document.querySelectorAll('.search-tab');
        tabs.forEach(tab => {
            tab.addEventListener('click', function() {
                tabs.forEach(t => t.classList.remove('active'));
                this.classList.add('active');
            });
        });

        // Set ngày mặc định
        const today = new Date();
        const checkin = new Date(today);
        checkin.setDate(today.getDate() + 4);
        const checkout = new Date(today);
        checkout.setDate(today.getDate() + 7);

        const dateInputs = document.querySelectorAll('input[type="date"]');
        if (dateInputs.length >= 2) {
            dateInputs[0].value = checkin.toISOString().split('T')[0];
            dateInputs[1].value = checkout.toISOString().split('T')[0];
        }

        // Animate cards on scroll
        const observerOptions = {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        };

        const observer = new IntersectionObserver(function(entries) {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        }, observerOptions);

        document.querySelectorAll('.offer-card, .destination-card').forEach(card => {
            card.style.opacity = '0';
            card.style.transform = 'translateY(20px)';
            card.style.transition = 'opacity 0.5s, transform 0.5s';
            observer.observe(card);
        });
    
/* END EXTERNAL SOURCE */
